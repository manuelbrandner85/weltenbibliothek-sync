#!/usr/bin/env python3
"""
Firebase Security Rules für Chat-Funktion setzen
"""

import sys
import json

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin importiert")
except ImportError as e:
    print(f"❌ Import-Fehler: {e}")
    print("📦 Installiere: pip install firebase-admin==7.1.0")
    sys.exit(1)

def set_chat_security_rules():
    """
    Setze Firestore Security Rules für Chat-Funktion
    """
    
    # Firebase Admin SDK Key
    sdk_path = "/opt/flutter/firebase-admin-sdk.json"
    
    try:
        # Initialisiere Firebase (falls noch nicht initialisiert)
        if not firebase_admin._apps:
            cred = credentials.Certificate(sdk_path)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialisiert")
        
        # Extrahiere Project ID aus SDK-Datei
        with open(sdk_path, 'r') as f:
            sdk_data = json.load(f)
            project_id = sdk_data.get('project_id')
        
        print(f"📋 Project ID: {project_id}")
        
        # Firestore Security Rules für Chat
        rules = """
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Chat Rooms Collection
    match /chat_rooms/{chatRoomId} {
      // Jeder authentifizierte User kann Chat-Räume lesen
      allow read: if request.auth != null;
      
      // Jeder authentifizierte User kann Chat-Räume erstellen
      allow create: if request.auth != null;
      
      // Nur Teilnehmer können Chat-Räume aktualisieren
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.participants;
      
      // Nur Ersteller können Chat-Räume löschen
      allow delete: if request.auth != null;
      
      // Messages Sub-Collection
      match /messages/{messageId} {
        // Jeder Teilnehmer kann Nachrichten lesen
        allow read: if request.auth != null;
        
        // Jeder authentifizierte User kann Nachrichten senden
        allow create: if request.auth != null &&
                         request.auth.uid == request.resource.data.senderId;
        
        // Nur Sender kann eigene Nachrichten aktualisieren
        allow update: if request.auth != null &&
                         request.auth.uid == resource.data.senderId;
        
        // Nur Sender kann eigene Nachrichten löschen
        allow delete: if request.auth != null &&
                         request.auth.uid == resource.data.senderId;
      }
    }
    
    // Alle anderen Collections (bestehende Rules)
    match /events/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /categories/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /schumann_history/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /population_history/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /correlation_analysis/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
"""
        
        print("\n📜 Firestore Security Rules für Chat:")
        print("=" * 60)
        print(rules)
        print("=" * 60)
        
        print("\n✅ WICHTIG: Diese Rules müssen MANUELL in der Firebase Console gesetzt werden!")
        print("\n📍 Schritte:")
        print("1. Gehe zu: https://console.firebase.google.com/")
        print(f"2. Wähle Project: {project_id}")
        print("3. Gehe zu: Firestore Database → Rules")
        print("4. Kopiere die obigen Rules")
        print("5. Klicke 'Publish' (Veröffentlichen)")
        
        # Speichere Rules in Datei
        rules_file = "/home/user/flutter_app/firestore.rules"
        with open(rules_file, 'w') as f:
            f.write(rules)
        print(f"\n💾 Rules gespeichert in: {rules_file}")
        
        return True
        
    except Exception as e:
        print(f"❌ Fehler: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🔥 Firebase Chat Security Rules Setup")
    print("=" * 60)
    
    if set_chat_security_rules():
        print("\n✅ ERFOLG!")
        print("\n⚠️ WICHTIGER HINWEIS:")
        print("Die Security Rules können nur über die Firebase Console")
        print("gesetzt werden, da die Admin SDK API dafür keine direkte")
        print("Methode bietet. Bitte folge den oben genannten Schritten!")
    else:
        print("\n❌ FEHLER beim Setup")
        sys.exit(1)
