import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Authentication Service
/// Verwaltet User-Authentifizierung mit Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Aktueller User
  User? get currentUser => _auth.currentUser;
  
  /// User Stream (für Real-time Updates)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Anonyme Anmeldung (für schnellen Start)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      // Erstelle User-Profil in Firestore
      if (userCredential.user != null) {
        await _createUserProfile(
          userCredential.user!,
          isAnonymous: true,
        );
      }
      
      return userCredential;
    } catch (e) {
      print('❌ Anonyme Anmeldung fehlgeschlagen: $e');
      return null;
    }
  }
  
  /// Email/Password Registrierung
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Setze Display Name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Erstelle User-Profil
      if (userCredential.user != null) {
        await _createUserProfile(
          userCredential.user!,
          displayName: displayName,
        );
      }
      
      return userCredential;
    } catch (e) {
      print('❌ Registrierung fehlgeschlagen: $e');
      return null;
    }
  }
  
  /// Email/Password Anmeldung
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('❌ Anmeldung fehlgeschlagen: $e');
      return null;
    }
  }
  
  /// Abmelden
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('❌ Abmeldung fehlgeschlagen: $e');
    }
  }
  
  /// User-Profil in Firestore erstellen
  Future<void> _createUserProfile(
    User user, {
    String? displayName,
    bool isAnonymous = false,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Prüfe ob Profil bereits existiert
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) return;
      
      // Erstelle neues Profil
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? 'Benutzer',
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'messageCount': 0,
        'favoriteCount': 0,
      });
    } catch (e) {
      print('❌ User-Profil Erstellung fehlgeschlagen: $e');
    }
  }
  
  /// Update Last Seen
  Future<void> updateLastSeen() async {
    if (currentUser == null) return;
    
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Last Seen Update fehlgeschlagen: $e');
    }
  }
  
  /// Get User Display Name
  String getUserDisplayName() {
    if (currentUser == null) return 'Gast';
    
    if (currentUser!.isAnonymous) {
      return 'Gast (${currentUser!.uid.substring(0, 8)})';
    }
    
    return currentUser!.displayName ?? 
           currentUser!.email?.split('@').first ?? 
           'Benutzer';
  }
  
  /// Get User ID
  String getUserId() {
    return currentUser?.uid ?? 'anonymous';
  }
  
  /// Get User ID (Alias für Kompatibilität)
  String? get currentUserId => currentUser?.uid;
  
  /// Ist angemeldet?
  bool get isSignedIn => currentUser != null;
  
  /// Ist anonym?
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
  
  /// Login mit Email/Password (Alias für Kompatibilität)
  Future<UserCredential?> loginWithEmailPassword(String email, String password) async {
    return await signInWithEmail(email, password);
  }
  
  /// Logout (Alias für Kompatibilität)
  Future<void> logout() async {
    return await signOut();
  }
  
  /// Stream User Profile (Kompatibilität)
  Stream<DocumentSnapshot> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
  
  /// Get User Profile (für edit_profile_screen.dart)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('❌ User-Profil abrufen fehlgeschlagen: $e');
      return null;
    }
  }
  
  /// Update User Profile (für edit_profile_screen.dart)
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
      
      // Update Firebase Auth displayName wenn vorhanden
      if (updates.containsKey('displayName') && currentUser != null) {
        await currentUser!.updateDisplayName(updates['displayName']);
      }
      
      return true;
    } catch (e) {
      print('❌ User-Profil Update fehlgeschlagen: $e');
      return false;
    }
  }
}
