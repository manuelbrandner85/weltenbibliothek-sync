#!/usr/bin/env python3
"""
Update Firebase Storage Security Rules
Erlaubt Upload und Download von Profilbildern
"""

import firebase_admin
from firebase_admin import credentials, storage
import sys

def update_storage_rules():
    """Aktualisiere Firebase Storage Rules"""
    try:
        # Initialize Firebase Admin SDK
        cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred, {
            'storageBucket': None  # Will be read from credentials
        })
        
        print("✅ Firebase Admin SDK initialisiert")
        
        # Storage Rules (als Reference - müssen manuell in Firebase Console gesetzt werden)
        storage_rules = """
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Profilbilder: User kann eigene Bilder uploaden und alle lesen
    match /profile_images/{userId}/{fileName} {
      allow read: if true;  // Jeder kann Profilbilder lesen
      allow write: if request.auth != null && request.auth.uid == userId;  // Nur eigener User kann schreiben
      allow delete: if request.auth != null && request.auth.uid == userId;  // Nur eigener User kann löschen
    }
    
    // Chat-Bilder: Authentifizierte User können uploaden und lesen
    match /chat_images/{chatRoomId}/{fileName} {
      allow read: if request.auth != null;  // Authentifizierte User können lesen
      allow write: if request.auth != null;  // Authentifizierte User können schreiben
    }
    
    // Voice Messages: Authentifizierte User können uploaden und lesen
    match /voice_messages/{chatRoomId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Standard: Alles andere blockieren
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
"""
        
        print("\n📋 Empfohlene Firebase Storage Rules:")
        print("=" * 60)
        print(storage_rules)
        print("=" * 60)
        
        print("\n⚠️  WICHTIG: Diese Rules müssen manuell in der Firebase Console gesetzt werden!")
        print("\n📍 Schritte:")
        print("1. Gehe zu: https://console.firebase.google.com/")
        print("2. Wähle dein Projekt")
        print("3. Storage → Rules")
        print("4. Kopiere die obigen Rules")
        print("5. Klicke 'Veröffentlichen'")
        
        return True
        
    except Exception as e:
        print(f"❌ Fehler: {e}")
        return False

if __name__ == '__main__':
    success = update_storage_rules()
    sys.exit(0 if success else 1)
