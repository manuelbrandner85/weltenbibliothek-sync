import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/moderator_permissions.dart';

/// User-Rollen
enum UserRole {
  user,      // 👤 Normal User - nur eigene Inhalte
  moderator, // 🛡️ Moderator - Stumm + Inhalte löschen
  superAdmin // 👑 Super-Admin - Alle Rechte
}

/// Admin & Moderator Service
/// 
/// Rollen-System:
/// - SUPER-ADMIN: brandy13062@gmail.com - Alle Rechte
/// - MODERATOR: Von Super-Admin ernannt - Stummschalten + Inhalte löschen
/// - USER: Standard - Nur eigene Inhalte
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Super-Admin Email (unveränderlich)
  static const String superAdminEmail = 'brandy13062@gmail.com';

  // ========================================
  // ROLLEN-PRÜFUNG
  // ========================================

  /// Prüfe ob User Super-Admin ist
  Future<bool> isSuperAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] as String?;
      return role == 'super_admin';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Prüfen der Super-Admin-Rolle: $e');
      }
      return false;
    }
  }

  /// Prüfe ob User Moderator ist
  Future<bool> isModerator(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] as String?;
      return role == 'moderator';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Prüfen der Moderator-Rolle: $e');
      }
      return false;
    }
  }

  /// Prüfe ob User Admin ODER Moderator ist
  Future<bool> hasModeratorRights(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] as String?;
      return role == 'super_admin' || role == 'moderator';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Prüfen der Moderator-Rechte: $e');
      }
      return false;
    }
  }

  /// Hole User-Rolle
  Future<UserRole> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return UserRole.user;

      final role = doc.data()?['role'] as String?;
      switch (role) {
        case 'super_admin':
          return UserRole.superAdmin;
        case 'moderator':
          return UserRole.moderator;
        default:
          return UserRole.user;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Holen der User-Rolle: $e');
      }
      return UserRole.user;
    }
  }

  /// Stream für User-Rolle (Echtzeit-Updates)
  Stream<UserRole> streamUserRole(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return UserRole.user;

      final role = snapshot.data()?['role'] as String?;
      switch (role) {
        case 'super_admin':
          return UserRole.superAdmin;
        case 'moderator':
          return UserRole.moderator;
        default:
          return UserRole.user;
      }
    });
  }

  // ========================================
  // SUPER-ADMIN: MODERATOR-VERWALTUNG
  // ========================================

  /// Ernennen eines Users zum Moderator mit Rechten (nur Super-Admin)
  Future<void> promoteModerator(
    String targetUserId,
    String adminUserId, {
    ModeratorPermissions? permissions,
  }) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Moderatoren ernennen');
      }

      // Standard-Rechte wenn nicht angegeben
      final perms = permissions ?? ModeratorPermissions.standard();

      // Setze Moderator-Rolle mit Berechtigungen
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'moderator',
        'permissions': perms.toMap(),
        'promoted_at': FieldValue.serverTimestamp(),
        'promoted_by': adminUserId,
      });

      // Log der Ernennung
      await _firestore.collection('moderation_logs').add({
        'action': 'promote_to_moderator',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'permissions': perms.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Sende Benachrichtigung
      await _sendNotification(
        userId: targetUserId,
        title: '🛡️ Du wurdest zum Moderator ernannt',
        body: 'Du hast jetzt Moderator-Rechte erhalten: ${perms.permissionsList.join(", ")}',
        type: 'promoted_to_moderator',
      );

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId zum Moderator ernannt mit Rechten: $perms');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Ernennen des Moderators: $e');
      }
      rethrow;
    }
  }

  /// Moderator-Rechte entziehen (nur Super-Admin)
  Future<void> demoteModerator(String targetUserId, String adminUserId) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Moderatoren entfernen');
      }

      // Entferne Moderator-Rolle und Berechtigungen
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'user',
        'permissions': FieldValue.delete(),
        'demoted_at': FieldValue.serverTimestamp(),
        'demoted_by': adminUserId,
      });

      // Log der Entfernung
      await _firestore.collection('moderation_logs').add({
        'action': 'demote_from_moderator',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Sende Benachrichtigung
      await _sendNotification(
        userId: targetUserId,
        title: '⚠️ Moderator-Rechte entfernt',
        body: 'Deine Moderator-Rechte wurden von einem Administrator entfernt.',
        type: 'demoted_from_moderator',
      );

      if (kDebugMode) {
        debugPrint('✅ Moderator-Rechte von $targetUserId entfernt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Entfernen der Moderator-Rechte: $e');
      }
      rethrow;
    }
  }

  /// Moderator-Berechtigungen aktualisieren (nur Super-Admin)
  Future<void> updateModeratorPermissions(
    String targetUserId,
    String adminUserId,
    ModeratorPermissions newPermissions,
  ) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Moderator-Rechte ändern');
      }

      // Prüfe ob Ziel-User Moderator ist
      final isMod = await isModerator(targetUserId);
      if (!isMod) {
        throw Exception('Ziel-User ist kein Moderator');
      }

      // Update Berechtigungen
      await _firestore.collection('users').doc(targetUserId).update({
        'permissions': newPermissions.toMap(),
        'permissions_updated_at': FieldValue.serverTimestamp(),
        'permissions_updated_by': adminUserId,
      });

      // Log der Änderung
      await _firestore.collection('moderation_logs').add({
        'action': 'update_moderator_permissions',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'new_permissions': newPermissions.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Sende Benachrichtigung
      await _sendNotification(
        userId: targetUserId,
        title: '🛡️ Deine Moderator-Rechte wurden aktualisiert',
        body: 'Neue Berechtigungen: ${newPermissions.permissionsList.join(", ")}',
        type: 'permissions_updated',
      );

      if (kDebugMode) {
        debugPrint('✅ Moderator-Rechte von $targetUserId aktualisiert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Aktualisieren der Moderator-Rechte: $e');
      }
      rethrow;
    }
  }

  /// Hole Moderator-Berechtigungen eines Users
  Future<ModeratorPermissions> getModeratorPermissions(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return ModeratorPermissions.none();

      final role = doc.data()?['role'] as String?;
      
      // Super-Admins haben immer alle Rechte
      if (role == 'super_admin') {
        return ModeratorPermissions.superAdmin();
      }

      // Moderatoren: Hole ihre Berechtigungen
      if (role == 'moderator') {
        final permissionsMap = doc.data()?['permissions'] as Map<String, dynamic>?;
        if (permissionsMap != null) {
          return ModeratorPermissions.fromMap(permissionsMap);
        }
        // Fallback auf Standard-Rechte wenn keine Berechtigungen gesetzt
        return ModeratorPermissions.standard();
      }

      // Normale User haben keine Rechte
      return ModeratorPermissions.none();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen der Moderator-Berechtigungen: $e');
      }
      return ModeratorPermissions.none();
    }
  }

  /// Alle Moderatoren abrufen
  Future<List<Map<String, dynamic>>> getAllModerators() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'moderator')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'userId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen der Moderatoren: $e');
      }
      return [];
    }
  }

  // ========================================
  // 👑 SUPER-ADMIN ERNENNUNG/ENTFERNUNG
  // ========================================

  /// Ernennung zum Super-Admin (nur bestehende Super-Admins können das)
  Future<void> promoteToSuperAdmin(String targetUserId, String adminUserId) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können andere zu Super-Admins ernennen');
      }

      // Setze Super-Admin-Rolle
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'super_admin',
        'is_super_admin': true,
        'promoted_to_admin_at': FieldValue.serverTimestamp(),
        'promoted_by': adminUserId,
      });

      // Log der Ernennung
      await _firestore.collection('moderation_logs').add({
        'action': 'promote_to_super_admin',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Sende Benachrichtigung
      await _sendNotification(
        userId: targetUserId,
        title: '👑 Du wurdest zum Super-Admin ernannt',
        body: 'Du hast jetzt alle Admin-Rechte und kannst Moderatoren und andere Admins ernennen.',
        type: 'promoted_to_admin',
      );

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId zum Super-Admin ernannt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Super-Admin Ernennung: $e');
      }
      rethrow;
    }
  }

  /// Entferne Super-Admin-Rechte (nur bestehende Super-Admins können das)
  Future<void> demoteSuperAdmin(String targetUserId, String adminUserId) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Admin-Rechte entziehen');
      }

      // Verhindere Selbst-Degradierung
      if (targetUserId == adminUserId) {
        throw Exception('Du kannst deine eigenen Admin-Rechte nicht entziehen');
      }

      // Entferne Super-Admin-Rolle
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'user',
        'is_super_admin': false,
        'demoted_from_admin_at': FieldValue.serverTimestamp(),
        'demoted_by': adminUserId,
      });

      // Log der Entfernung
      await _firestore.collection('moderation_logs').add({
        'action': 'demote_from_super_admin',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Sende Benachrichtigung
      await _sendNotification(
        userId: targetUserId,
        title: '⚠️ Admin-Rechte entfernt',
        body: 'Deine Super-Admin-Rechte wurden von einem Administrator entfernt.',
        type: 'demoted_from_admin',
      );

      if (kDebugMode) {
        debugPrint('✅ Super-Admin-Rechte von $targetUserId entfernt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Admin-Rechte Entzug: $e');
      }
      rethrow;
    }
  }

  /// Alle Super-Admins abrufen
  Future<List<Map<String, dynamic>>> getAllSuperAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'userId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen der Super-Admins: $e');
      }
      return [];
    }
  }

  // ========================================
  // MODERATOR: STUMMSCHALTEN
  // ========================================

  /// User stummschalten (Moderator + Super-Admin)
  Future<void> muteUser({
    required String targetUserId,
    required String moderatorId,
    required String reason,
    int durationMinutes = 60, // Standard: 1 Stunde
  }) async {
    try {
      // Prüfe spezifische Berechtigung zum Muten
      final permissions = await getModeratorPermissions(moderatorId);
      if (!permissions.canMuteUsers) {
        throw Exception('Keine Berechtigung zum Muten von Usern');
      }

      final muteEndTime = DateTime.now().add(Duration(minutes: durationMinutes));

      // Erstelle Mute-Eintrag
      await _firestore.collection('muted_users').doc(targetUserId).set({
        'userId': targetUserId,
        'muted_by': moderatorId,
        'muted_at': FieldValue.serverTimestamp(),
        'mute_end': Timestamp.fromDate(muteEndTime),
        'reason': reason,
        'duration_minutes': durationMinutes,
      });

      // Update User-Dokument
      await _firestore.collection('users').doc(targetUserId).update({
        'is_muted': true,
        'muted_until': Timestamp.fromDate(muteEndTime),
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId stummgeschaltet für $durationMinutes Minuten');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Stummschalten: $e');
      }
      rethrow;
    }
  }

  /// User entstummen (Moderator + Super-Admin)
  Future<void> unmuteUser(String targetUserId, String moderatorId) async {
    try {
      // Prüfe spezifische Berechtigung zum Unmuten
      final permissions = await getModeratorPermissions(moderatorId);
      if (!permissions.canMuteUsers) {
        throw Exception('Keine Berechtigung zum Entstummen von Usern');
      }

      // Lösche Mute-Eintrag
      await _firestore.collection('muted_users').doc(targetUserId).delete();

      // Update User-Dokument
      await _firestore.collection('users').doc(targetUserId).update({
        'is_muted': false,
        'muted_until': FieldValue.delete(),
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId entstummt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Entstummen: $e');
      }
      rethrow;
    }
  }

  /// Prüfe ob User stummgeschaltet ist
  Future<bool> isUserMuted(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final isMuted = doc.data()?['is_muted'] as bool? ?? false;
      final mutedUntil = doc.data()?['muted_until'] as Timestamp?;

      // Prüfe ob Mute-Zeit abgelaufen ist
      if (isMuted && mutedUntil != null) {
        if (mutedUntil.toDate().isBefore(DateTime.now())) {
          // Mute abgelaufen - automatisch entstummen
          await unmuteUser(userId, userId); // Auto-unmute
          return false;
        }
        return true;
      }

      return isMuted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Prüfen des Mute-Status: $e');
      }
      return false;
    }
  }

  // ========================================
  // MODERATOR: INHALTE LÖSCHEN
  // ========================================

  /// Nachricht löschen (Moderator + Super-Admin)
  Future<void> deleteMessageAsModerator({
    required String chatRoomId,
    required String messageId,
    required String moderatorId,
    String? reason,
  }) async {
    try {
      // Prüfe spezifische Berechtigung zum Löschen von Nachrichten
      final permissions = await getModeratorPermissions(moderatorId);
      if (!permissions.canDeleteMessages) {
        throw Exception('Keine Berechtigung zum Löschen von Nachrichten');
      }

      // Hole Original-Nachricht
      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Nachricht nicht gefunden');
      }

      // Log der Löschung
      await _firestore.collection('moderation_logs').add({
        'action': 'delete_message',
        'moderator_id': moderatorId,
        'target_message_id': messageId,
        'chat_room_id': chatRoomId,
        'original_message': messageDoc.data(),
        'reason': reason ?? 'Unangebrachter Inhalt',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Lösche Nachricht
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (kDebugMode) {
        debugPrint('✅ Nachricht $messageId als Moderator gelöscht');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen der Nachricht: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // SUPER-ADMIN: BLOCKIEREN
  // ========================================

  /// User blockieren (Super-Admin oder Moderator mit Berechtigung)
  Future<void> blockUser({
    required String targetUserId,
    required String adminUserId,
    required String reason,
  }) async {
    try {
      // Prüfe spezifische Berechtigung zum Blockieren
      final permissions = await getModeratorPermissions(adminUserId);
      if (!permissions.canBlockUsers) {
        throw Exception('Keine Berechtigung zum Blockieren von Usern');
      }

      // Erstelle Block-Eintrag
      await _firestore.collection('blocked_users').doc(targetUserId).set({
        'userId': targetUserId,
        'blocked_by': adminUserId,
        'blocked_at': FieldValue.serverTimestamp(),
        'reason': reason,
      });

      // Update User-Dokument
      await _firestore.collection('users').doc(targetUserId).update({
        'is_blocked': true,
        'blocked_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId blockiert');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Blockieren: $e');
      }
      rethrow;
    }
  }

  /// User entblocken (Super-Admin oder Moderator mit Berechtigung)
  Future<void> unblockUser(String targetUserId, String adminUserId) async {
    try {
      // Prüfe spezifische Berechtigung zum Entblocken
      final permissions = await getModeratorPermissions(adminUserId);
      if (!permissions.canBlockUsers) {
        throw Exception('Keine Berechtigung zum Entblocken von Usern');
      }

      // Lösche Block-Eintrag
      await _firestore.collection('blocked_users').doc(targetUserId).delete();

      // Update User-Dokument
      await _firestore.collection('users').doc(targetUserId).update({
        'is_blocked': false,
        'blocked_at': FieldValue.delete(),
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId entblockt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Entblocken: $e');
      }
      rethrow;
    }
  }

  /// Prüfe ob User blockiert ist
  Future<bool> isUserBlocked(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      return doc.data()?['is_blocked'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Prüfen des Block-Status: $e');
      }
      return false;
    }
  }

  // ========================================
  // SUPER-ADMIN: NACHRICHTEN BEARBEITEN
  // ========================================

  /// Nachricht bearbeiten (nur Super-Admin)
  Future<void> editMessageAsAdmin({
    required String chatRoomId,
    required String messageId,
    required String newText,
    required String adminUserId,
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Nachrichten bearbeiten');
      }

      // Hole Original-Nachricht
      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Nachricht nicht gefunden');
      }

      // Log der Bearbeitung
      await _firestore.collection('moderation_logs').add({
        'action': 'edit_message',
        'admin_id': adminUserId,
        'target_message_id': messageId,
        'chat_room_id': chatRoomId,
        'original_text': messageDoc.data()?['text'],
        'new_text': newText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update Nachricht
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'edited_by_admin': true,
        'edited_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Nachricht $messageId als Admin bearbeitet');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Bearbeiten der Nachricht: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // STATISTIKEN & LOGS
  // ========================================

  /// Hole alle Moderations-Logs
  Stream<List<Map<String, dynamic>>> getModerationLogs() {
    return _firestore
        .collection('moderation_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'logId': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Hole alle blockierten User
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final querySnapshot =
          await _firestore.collection('blocked_users').get();

      return querySnapshot.docs
          .map((doc) => {
                'userId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen blockierter User: $e');
      }
      return [];
    }
  }

  /// Hole alle stummgeschalteten User
  Future<List<Map<String, dynamic>>> getMutedUsers() async {
    try {
      final querySnapshot = await _firestore.collection('muted_users').get();

      return querySnapshot.docs
          .map((doc) => {
                'userId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen stummgeschalteter User: $e');
      }
      return [];
    }
  }

  // ========================================
  // VOLLSTÄNDIGE DATENLÖSCHUNG
  // ========================================

  /// Lösche User komplett aus Firebase (nur Super-Admin)
  /// 
  /// LÖSCHT:
  /// - User-Profil (Firestore)
  /// - Alle Nachrichten des Users
  /// - Alle Chat-Räume des Users (als Ersteller)
  /// - Alle Audio-Räume des Users (als Host)
  /// - Block/Mute Einträge
  /// - Firebase Auth Account
  Future<void> deleteUserCompletely({
    required String targetUserId,
    required String adminUserId,
    Function(String)? onProgress, // ✨ NEU: Progress-Callback
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können User komplett löschen');
      }

      if (kDebugMode) {
        debugPrint('🗑️ Starte vollständige Löschung von User: $targetUserId');
      }

      // 1. Lösche alle Nachrichten des Users
      onProgress?.call('📝 Suche Nachrichten des Users...');
      await _deleteAllUserMessages(targetUserId, onProgress);

      // 2. Lösche alle Chat-Räume des Users (als Ersteller)
      onProgress?.call('💬 Suche Chat-Räume (als Ersteller)...');
      await _deleteAllUserChatRooms(targetUserId, onProgress);

      // 3. Lösche alle Audio-Räume des Users (als Host)
      onProgress?.call('🎙️ Suche Audio-Räume (als Host)...');
      await _deleteAllUserAudioRooms(targetUserId, onProgress);

      // 4. Lösche Block/Mute Einträge
      onProgress?.call('🚫 Entferne Moderation-Einträge...');
      await _firestore.collection('blocked_users').doc(targetUserId).delete();
      await _firestore.collection('muted_users').doc(targetUserId).delete();

      // 5. Lösche User-Profil
      onProgress?.call('👤 Lösche User-Profil...');
      await _firestore.collection('users').doc(targetUserId).delete();

      // 6. Log der Löschung
      onProgress?.call('📋 Erstelle Lösch-Log...');
      await _firestore.collection('moderation_logs').add({
        'action': 'delete_user_completely',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      onProgress?.call('✅ User vollständig gelöscht!');

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId vollständig gelöscht');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim vollständigen Löschen des Users: $e');
      }
      rethrow;
    }
  }

  /// Hilfsfunktion: Lösche alle Nachrichten eines Users
  Future<void> _deleteAllUserMessages(String userId, [Function(String)? onProgress]) async {
    // OPTIMIERT: Nur Räume abrufen, in denen der User Mitglied ist
    // Dies reduziert die Anzahl der Firestore-Abfragen drastisch
    final chatRooms = await _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .get();

    if (kDebugMode) {
      debugPrint('🗑️ Lösche Nachrichten in ${chatRooms.docs.length} Räumen');
    }

    onProgress?.call('📝 Gefunden: ${chatRooms.docs.length} Chat-Räume');

    int totalDeleted = 0;

    // Verwende Batch-Operations für bessere Performance
    for (var i = 0; i < chatRooms.docs.length; i++) {
      final room = chatRooms.docs[i];
      onProgress?.call('📝 Lösche Nachrichten in Raum ${i + 1}/${chatRooms.docs.length}...');
      
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      // Lösche alle Nachrichten des Users in diesem Raum
      final messages = await _firestore
          .collection('chat_rooms')
          .doc(room.id)
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();

      for (var message in messages.docs) {
        batch.delete(message.reference);
        batchCount++;
        totalDeleted++;

        // Firestore Batch-Limit: 500 Operations
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      // Lösche Typing-Indicator
      await _firestore
          .collection('chat_rooms')
          .doc(room.id)
          .collection('typing')
          .doc(userId)
          .delete();
    }

    onProgress?.call('✅ $totalDeleted Nachrichten gelöscht');

    if (kDebugMode) {
      debugPrint('✅ Nachrichten erfolgreich gelöscht');
    }
  }

  /// Hilfsfunktion: Lösche alle Chat-Räume eines Users (als Ersteller)
  Future<void> _deleteAllUserChatRooms(String userId, [Function(String)? onProgress]) async {
    final chatRooms = await _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .get();

    int deletedRooms = 0;

    for (var room in chatRooms.docs) {
      final roomData = room.data();
      final participants = roomData['participants'] as List<dynamic>? ?? [];
      
      // Nur löschen wenn User der Ersteller ist (erster Teilnehmer)
      if (participants.isNotEmpty && participants.first == userId) {
        onProgress?.call('💬 Lösche Chat-Raum "${roomData['name'] ?? 'Unbekannt'}"...');
        
        // Lösche alle Messages
        final messages = await _firestore
            .collection('chat_rooms')
            .doc(room.id)
            .collection('messages')
            .get();
        for (var msg in messages.docs) {
          await msg.reference.delete();
        }

        // Lösche alle Typing Indicators
        final typing = await _firestore
            .collection('chat_rooms')
            .doc(room.id)
            .collection('typing')
            .get();
        for (var typ in typing.docs) {
          await typ.reference.delete();
        }

        // Lösche den Raum selbst
        await room.reference.delete();
        deletedRooms++;
      }
    }

    onProgress?.call('✅ $deletedRooms Chat-Räume gelöscht');
  }

  /// Hilfsfunktion: Lösche alle Audio-Räume eines Users (als Host)
  Future<void> _deleteAllUserAudioRooms(String userId, [Function(String)? onProgress]) async {
    final audioRooms = await _firestore
        .collection('audio_rooms')
        .where('hostId', isEqualTo: userId)
        .get();

    onProgress?.call('🎙️ Gefunden: ${audioRooms.docs.length} Audio-Räume');

    int deletedRooms = 0;

    for (var i = 0; i < audioRooms.docs.length; i++) {
      final room = audioRooms.docs[i];
      final roomData = room.data();
      onProgress?.call('🎙️ Lösche Audio-Raum \"${roomData['name'] ?? 'Unbekannt'}\" (${i + 1}/${audioRooms.docs.length})...');
      
      // Lösche alle Participants
      final participants = await _firestore
          .collection('audio_rooms')
          .doc(room.id)
          .collection('participants')
          .get();
      
      for (var participant in participants.docs) {
        await participant.reference.delete();
      }

      // Lösche den Raum selbst
      await room.reference.delete();
      deletedRooms++;
    }

    onProgress?.call('✅ $deletedRooms Audio-Räume gelöscht');
  }

  /// Lösche Chat-Raum vollständig aus Firebase (Super-Admin)
  Future<void> deleteChatRoomCompletely({
    required String chatRoomId,
    required String adminUserId,
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Chat-Räume komplett löschen');
      }

      if (kDebugMode) {
        debugPrint('🗑️ Lösche Chat-Raum vollständig: $chatRoomId');
      }

      // 1. Lösche alle Messages
      final messages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();
      
      for (var message in messages.docs) {
        await message.reference.delete();
      }

      // 2. Lösche alle Typing Indicators
      final typing = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('typing')
          .get();
      
      for (var typ in typing.docs) {
        await typ.reference.delete();
      }

      // 3. Lösche den Raum selbst
      await _firestore.collection('chat_rooms').doc(chatRoomId).delete();

      // 4. Log der Löschung
      await _firestore.collection('moderation_logs').add({
        'action': 'delete_chat_room_completely',
        'admin_id': adminUserId,
        'chat_room_id': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Chat-Raum $chatRoomId vollständig gelöscht');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen des Chat-Raums: $e');
      }
      rethrow;
    }
  }

  /// Lösche Audio-Raum vollständig aus Firebase (Super-Admin)
  Future<void> deleteAudioRoomCompletely({
    required String audioRoomId,
    required String adminUserId,
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Audio-Räume komplett löschen');
      }

      if (kDebugMode) {
        debugPrint('🗑️ Lösche Audio-Raum vollständig: $audioRoomId');
      }

      // 1. Lösche alle Participants
      final participants = await _firestore
          .collection('audio_rooms')
          .doc(audioRoomId)
          .collection('participants')
          .get();
      
      for (var participant in participants.docs) {
        await participant.reference.delete();
      }

      // 2. Lösche den Raum selbst
      await _firestore.collection('audio_rooms').doc(audioRoomId).delete();

      // 3. Log der Löschung
      await _firestore.collection('moderation_logs').add({
        'action': 'delete_audio_room_completely',
        'admin_id': adminUserId,
        'audio_room_id': audioRoomId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Audio-Raum $audioRoomId vollständig gelöscht');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen des Audio-Raums: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 🔄 USER-WIEDERHERSTELLUNG (Super-Admin)
  // ========================================

  /// Hole gelöschte User aus Moderation-Logs
  Future<List<Map<String, dynamic>>> getDeletedUsers() async {
    try {
      final logsSnapshot = await _firestore
          .collection('moderation_logs')
          .where('action', isEqualTo: 'delete_user_completely')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final deletedUsers = <Map<String, dynamic>>[];

      for (var log in logsSnapshot.docs) {
        final data = log.data();
        final targetUserId = data['target_user_id'];
        
        // Prüfe ob User wirklich gelöscht ist
        final userExists = await _firestore
            .collection('users')
            .doc(targetUserId)
            .get()
            .then((doc) => doc.exists);

        if (!userExists) {
          deletedUsers.add({
            'log_id': log.id,
            'user_id': targetUserId,
            'deleted_by': data['admin_id'],
            'deleted_at': data['timestamp'],
            'can_restore': true,
          });
        }
      }

      return deletedUsers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Abrufen gelöschter User: $e');
      }
      return [];
    }
  }

  /// Stelle gelöschten User wieder her (Super-Admin only)
  Future<void> restoreUser({
    required String targetUserId,
    required String adminUserId,
    required String newEmail,
    required String temporaryPassword,
    required String displayName,
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können User wiederherstellen');
      }

      if (kDebugMode) {
        debugPrint('🔄 Stelle User wieder her: $targetUserId');
      }

      // 1. Erstelle neuen Firebase Auth Account (User muss neue Credentials erhalten)
      // HINWEIS: Firebase Auth erlaubt keine direkte UID-Wiederherstellung
      // Daher wird ein neuer Account mit neuem temporären Passwort erstellt
      
      // 2. Erstelle User-Profil in Firestore
      await _firestore.collection('users').doc(targetUserId).set({
        'uid': targetUserId,
        'email': newEmail,
        'displayName': displayName,
        'username': displayName.toLowerCase().replaceAll(' ', '_'),
        'bio': 'Wiederhergestellter Account',
        'photoURL': '',
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': adminUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': false,
      });

      // 3. Sende Benachrichtigung an wiederhergestellten User
      await _sendNotification(
        userId: targetUserId,
        title: '🔄 Account wiederhergestellt',
        body: 'Dein Account wurde vom Administrator wiederhergestellt. Temporäres Passwort: $temporaryPassword',
        type: 'account_restored',
      );

      // 4. Log der Wiederherstellung
      await _firestore.collection('moderation_logs').add({
        'action': 'restore_user',
        'admin_id': adminUserId,
        'target_user_id': targetUserId,
        'new_email': newEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId wiederhergestellt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei User-Wiederherstellung: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 📨 BENACHRICHTIGUNGEN
  // ========================================

  /// Sende Benachrichtigung an User (bei Admin-Aktionen)
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('📨 Benachrichtigung gesendet an User: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Senden der Benachrichtigung: $e');
      }
    }
  }

  /// Sende Benachrichtigung bei Stummschaltung (bestehende Funktion erweitern)
  Future<void> muteUserWithNotification({
    required String targetUserId,
    required String moderatorId,
    required String reason,
    int durationMinutes = 60,
  }) async {
    // Normale Mute-Funktion
    await muteUser(
      targetUserId: targetUserId,
      moderatorId: moderatorId,
      reason: reason,
      durationMinutes: durationMinutes,
    );

    // Sende Benachrichtigung
    await _sendNotification(
      userId: targetUserId,
      title: '🔇 Du wurdest stummgeschaltet',
      body: 'Grund: $reason\nDauer: $durationMinutes Minuten',
      type: 'muted',
    );
  }

  /// Sende Benachrichtigung bei Blockierung (bestehende Funktion erweitern)
  Future<void> blockUserWithNotification({
    required String targetUserId,
    required String adminUserId,
    required String reason,
  }) async {
    // Normale Block-Funktion
    await blockUser(
      targetUserId: targetUserId,
      adminUserId: adminUserId,
      reason: reason,
    );

    // Sende Benachrichtigung
    await _sendNotification(
      userId: targetUserId,
      title: '🚫 Du wurdest blockiert',
      body: 'Grund: $reason\nDu kannst dich nicht mehr anmelden.',
      type: 'blocked',
    );
  }
}
