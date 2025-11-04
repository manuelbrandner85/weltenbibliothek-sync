import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  /// Ernennen eines Users zum Moderator (nur Super-Admin)
  Future<void> promoteModerator(String targetUserId, String adminUserId) async {
    try {
      // Prüfe ob Admin Super-Admin ist
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können Moderatoren ernennen');
      }

      // Setze Moderator-Rolle
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'moderator',
        'promoted_at': FieldValue.serverTimestamp(),
        'promoted_by': adminUserId,
      });

      if (kDebugMode) {
        debugPrint('✅ User $targetUserId zum Moderator ernannt');
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

      // Entferne Moderator-Rolle
      await _firestore.collection('users').doc(targetUserId).update({
        'role': 'user',
        'demoted_at': FieldValue.serverTimestamp(),
        'demoted_by': adminUserId,
      });

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
      // Prüfe Moderator-Rechte
      final hasModerationRights = await hasModeratorRights(moderatorId);
      if (!hasModerationRights) {
        throw Exception('Keine Moderator-Rechte');
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
      // Prüfe Moderator-Rechte
      final hasModerationRights = await hasModeratorRights(moderatorId);
      if (!hasModerationRights) {
        throw Exception('Keine Moderator-Rechte');
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
      // Prüfe Moderator-Rechte
      final hasModerationRights = await hasModeratorRights(moderatorId);
      if (!hasModerationRights) {
        throw Exception('Keine Moderator-Rechte');
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

  /// User blockieren (nur Super-Admin)
  Future<void> blockUser({
    required String targetUserId,
    required String adminUserId,
    required String reason,
  }) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können User blockieren');
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

  /// User entblocken (nur Super-Admin)
  Future<void> unblockUser(String targetUserId, String adminUserId) async {
    try {
      // Prüfe Super-Admin-Rechte
      final isAdmin = await isSuperAdmin(adminUserId);
      if (!isAdmin) {
        throw Exception('Nur Super-Admins können User entblocken');
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
}
