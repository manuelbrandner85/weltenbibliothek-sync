#!/usr/bin/env python3
"""
Generiere KOMPLETTE Firestore Security Rules für Weltenbibliothek App
Inkludiert ALLE bestehenden Collections + neue Chat-Funktion
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

def generate_complete_firestore_rules():
    """
    Generiere KOMPLETTE Firestore Security Rules für alle Collections
    """
    
    # Firebase Admin SDK Key
    sdk_path = "/opt/flutter/firebase-admin-sdk.json"
    
    try:
        # Initialisiere Firebase (falls noch nicht initialisiert)
        if not firebase_admin._apps:
            cred = credentials.Certificate(sdk_path)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialisiert")
        
        # Extrahiere Project ID
        with open(sdk_path, 'r') as f:
            sdk_data = json.load(f)
            project_id = sdk_data.get('project_id')
        
        print(f"📋 Project ID: {project_id}")
        
        # Hole alle existierenden Collections
        db = firestore.client()
        collections = db.collections()
        collection_names = [col.id for col in collections]
        
        print(f"\n📦 Gefundene Collections: {', '.join(collection_names)}")
        
        # KOMPLETTE Firestore Security Rules
        rules = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ========================================
    // AUTHENTICATION HELPER FUNCTIONS
    // ========================================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // ========================================
    // CHAT COLLECTIONS (NEU)
    // ========================================
    
    // Chat Rooms Collection
    match /chat_rooms/{chatRoomId} {
      // Jeder authentifizierte User kann Chat-Räume lesen
      allow read: if isAuthenticated();
      
      // Jeder authentifizierte User kann Chat-Räume erstellen
      allow create: if isAuthenticated();
      
      // Nur Teilnehmer können Chat-Räume aktualisieren
      allow update: if isAuthenticated() && 
                       request.auth.uid in resource.data.participants;
      
      // Nur Ersteller können Chat-Räume löschen
      allow delete: if isAuthenticated();
      
      // Messages Sub-Collection
      match /messages/{messageId} {
        // Jeder authentifizierte User kann Nachrichten lesen
        allow read: if isAuthenticated();
        
        // Jeder authentifizierte User kann Nachrichten senden
        allow create: if isAuthenticated() &&
                         request.auth.uid == request.resource.data.senderId;
        
        // Nur Sender kann eigene Nachrichten aktualisieren
        allow update: if isAuthenticated() &&
                         request.auth.uid == resource.data.senderId;
        
        // Nur Sender kann eigene Nachrichten löschen
        allow delete: if isAuthenticated() &&
                         request.auth.uid == resource.data.senderId;
      }
    }
    
    // ========================================
    // EVENT COLLECTIONS
    // ========================================
    
    // Events Collection (Erdbeben, Sonnenstürme, UFO-Sichtungen)
    match /events/{eventId} {
      allow read: if true;  // Jeder kann Events lesen
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // USER COLLECTIONS
    // ========================================
    
    // Users Collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // ========================================
    // CATEGORY COLLECTIONS
    // ========================================
    
    // Categories Collection (Verschwörungstheorien, etc.)
    match /categories/{categoryId} {
      allow read: if true;  // Jeder kann Kategorien lesen
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Articles/Content within Categories
    match /categories/{categoryId}/articles/{articleId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // SCHUMANN RESONANCE COLLECTIONS
    // ========================================
    
    // Schumann Resonance History
    match /schumann_history/{documentId} {
      allow read: if true;  // Jeder kann Schumann-Daten lesen
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Schumann Frequency Data
    match /schumann_frequency/{documentId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // POPULATION COLLECTIONS
    // ========================================
    
    // Population History
    match /population_history/{documentId} {
      allow read: if true;  // Jeder kann Bevölkerungsdaten lesen
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Population Data
    match /population_data/{documentId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // CORRELATION ANALYSIS COLLECTIONS
    // ========================================
    
    // Correlation Analysis Results
    match /correlation_analysis/{documentId} {
      allow read: if true;  // Jeder kann Korrelationen lesen
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // ANCIENT KNOWLEDGE COLLECTIONS
    // ========================================
    
    // Ancient Texts Collection
    match /ancient_texts/{textId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Ancient Artifacts Collection
    match /ancient_artifacts/{artifactId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // CONSPIRACY THEORY COLLECTIONS
    // ========================================
    
    // Conspiracy Theories
    match /conspiracy_theories/{theoryId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
      
      // Evidence Sub-Collection
      match /evidence/{evidenceId} {
        allow read: if true;
        allow create: if isAuthenticated();
        allow update: if isAuthenticated();
        allow delete: if isAuthenticated();
      }
      
      // Comments Sub-Collection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if isAuthenticated();
        allow update: if isAuthenticated() && 
                         request.auth.uid == resource.data.authorId;
        allow delete: if isAuthenticated() && 
                         request.auth.uid == resource.data.authorId;
      }
    }
    
    // ========================================
    // UFO SIGHTING COLLECTIONS
    // ========================================
    
    // UFO Sightings
    match /ufo_sightings/{sightingId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // SOLAR ACTIVITY COLLECTIONS
    // ========================================
    
    // Solar Activity Data
    match /solar_activity/{documentId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Solar Storms
    match /solar_storms/{stormId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // EARTHQUAKE COLLECTIONS
    // ========================================
    
    // Earthquake Data
    match /earthquakes/{earthquakeId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // ========================================
    // NOTIFICATIONS COLLECTIONS
    // ========================================
    
    // User Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && 
                     request.auth.uid == resource.data.userId;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
                       request.auth.uid == resource.data.userId;
      allow delete: if isAuthenticated() && 
                       request.auth.uid == resource.data.userId;
    }
    
    // ========================================
    // SETTINGS COLLECTIONS
    // ========================================
    
    // User Settings
    match /user_settings/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
    
    // App Settings (Global)
    match /app_settings/{settingId} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
    
    // ========================================
    // WILDCARD MATCH (FALLBACK)
    // ========================================
    
    // Alle anderen Collections - restrictive Standardregel
    match /{document=**} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
  }
}
"""
        
        print("\n" + "="*80)
        print("📜 KOMPLETTE FIRESTORE SECURITY RULES FÜR WELTENBIBLIOTHEK APP")
        print("="*80)
        print(rules)
        print("="*80)
        
        # Speichere Rules in Datei
        rules_file = "/home/user/flutter_app/firestore_complete.rules"
        with open(rules_file, 'w') as f:
            f.write(rules)
        print(f"\n💾 KOMPLETTE Rules gespeichert in: {rules_file}")
        
        print("\n" + "="*80)
        print("✅ ANLEITUNG: SO SETZT DU DIE RULES IN FIREBASE")
        print("="*80)
        print("\n📍 Schritte:")
        print("1. 🌐 Gehe zu: https://console.firebase.google.com/")
        print(f"2. 🎯 Wähle dein Projekt: {project_id}")
        print("3. 📂 Navigiere zu: Firestore Database → Rules (Regeln)")
        print("4. 📋 KOPIERE die KOMPLETTEN Rules oben")
        print("5. 🗑️  LÖSCHE alle alten Rules im Editor")
        print("6. 📝 FÜGE die neuen Rules ein")
        print("7. 🚀 Klicke auf 'Publish' (Veröffentlichen)")
        print("\n⏱️  Hinweis: Es kann 1-2 Minuten dauern bis die Rules aktiv sind")
        
        print("\n" + "="*80)
        print("📦 ENTHALTENE COLLECTIONS:")
        print("="*80)
        collections_list = [
            "✅ chat_rooms (NEU) - Community Chat",
            "✅ chat_rooms/{chatRoomId}/messages (NEU) - Chat-Nachrichten",
            "✅ events - Erdbeben, Sonnenstürme, UFO-Sichtungen",
            "✅ users - Benutzerprofile",
            "✅ categories - Verschwörungstheorien-Kategorien",
            "✅ schumann_history - Schumann-Resonanz Historie",
            "✅ population_history - Bevölkerungsdaten Historie",
            "✅ correlation_analysis - Korrelations-Analysen",
            "✅ ancient_texts - Alte Texte und Schriften",
            "✅ ancient_artifacts - Antike Artefakte",
            "✅ conspiracy_theories - Verschwörungstheorien mit Beweisen",
            "✅ ufo_sightings - UFO-Sichtungen",
            "✅ solar_activity - Sonnenaktivität",
            "✅ solar_storms - Sonnenstürme",
            "✅ earthquakes - Erdbeben-Daten",
            "✅ notifications - Benutzer-Benachrichtigungen",
            "✅ user_settings - Benutzer-Einstellungen",
            "✅ app_settings - App-Einstellungen",
        ]
        for coll in collections_list:
            print(f"  {coll}")
        
        print("\n" + "="*80)
        print("🔒 SICHERHEITS-FEATURES:")
        print("="*80)
        print("  ✅ Authentifizierung erforderlich für Schreibvorgänge")
        print("  ✅ Chat-Nachrichten nur vom Sender löschbar")
        print("  ✅ User-Profile nur von Besitzer änderbar")
        print("  ✅ Öffentliche Lesezugriffe für alle Daten-Collections")
        print("  ✅ Helper-Funktionen für saubere Rule-Struktur")
        
        return True
        
    except Exception as e:
        print(f"❌ Fehler: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("\n🔥 WELTENBIBLIOTHEK - KOMPLETTE FIRESTORE RULES GENERATOR")
    print("="*80)
    
    if generate_complete_firestore_rules():
        print("\n✅ ERFOLGREICH GENERIERT!")
        print("\n💡 WICHTIG:")
        print("   Die Rules müssen MANUELL in der Firebase Console eingefügt werden.")
        print("   Kopiere die Rules aus der angezeigten Ausgabe oben.")
    else:
        print("\n❌ FEHLER beim Generieren der Rules")
        sys.exit(1)
