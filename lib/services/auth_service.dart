import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service für Multi-User System
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current User
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrierung mit Email & Password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Registriere neuen User: $email');
      }

      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user profile in Firestore
      await _createUserProfile(
        userId: userCredential.user!.uid,
        email: email,
        displayName: displayName,
      );

      if (kDebugMode) {
        debugPrint('✅ User erfolgreich registriert: ${userCredential.user?.uid}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registrierung fehlgeschlagen: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Login mit Email & Password
  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Login User: $email');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✅ Login erfolgreich: ${userCredential.user?.uid}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login fehlgeschlagen: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Logout User: ${currentUser?.uid}');
      }

      await _auth.signOut();

      if (kDebugMode) {
        debugPrint('✅ Logout erfolgreich');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Logout fehlgeschlagen: $e');
      }
      rethrow;
    }
  }

  /// Password Reset Email senden
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        debugPrint('✅ Password Reset Email gesendet an: $email');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// User Profile in Firestore erstellen
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'displayName': displayName,
        'username': displayName.toLowerCase().replaceAll(' ', '_'),
        'bio': '',
        'photoURL': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      });

      if (kDebugMode) {
        debugPrint('✅ User Profile erstellt in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Erstellen des Profiles: $e');
      }
      rethrow;
    }
  }

  /// Firebase Auth Exception Handler
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Das Passwort ist zu schwach. Mindestens 6 Zeichen erforderlich.';
      case 'email-already-in-use':
        return 'Diese Email-Adresse wird bereits verwendet.';
      case 'invalid-email':
        return 'Ungültige Email-Adresse.';
      case 'user-not-found':
        return 'Kein Benutzer mit dieser Email gefunden.';
      case 'wrong-password':
        return 'Falsches Passwort.';
      case 'user-disabled':
        return 'Dieser Benutzer wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Anmeldeversuche. Bitte versuche es später erneut.';
      case 'operation-not-allowed':
        return 'Email/Password-Anmeldung ist nicht aktiviert.';
      default:
        return 'Ein Fehler ist aufgetreten: ${e.message}';
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler bei Username-Check: $e');
      }
      return false;
    }
  }

  /// Get User Profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des User Profiles: $e');
      }
      return null;
    }
  }

  /// Update User Profile
  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    String? bio,
    String? photoURL,
  }) async {
    if (currentUserId == null) return;

    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        updates['displayName'] = displayName;
        await currentUser?.updateDisplayName(displayName);
      }
      
      if (username != null) {
        updates['username'] = username.toLowerCase();
      }
      
      if (bio != null) {
        updates['bio'] = bio;
      }
      
      if (photoURL != null) {
        updates['photoURL'] = photoURL;
        await currentUser?.updatePhotoURL(photoURL);
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(currentUserId).update(updates);
        
        if (kDebugMode) {
          debugPrint('✅ User Profile aktualisiert');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Aktualisieren des Profiles: $e');
      }
      rethrow;
    }
  }

  /// Update Online Status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Aktualisieren des Online-Status: $e');
      }
    }
  }

  /// Stream User Profile
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}
