#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
🔥 FIREBASE SETUP - KOMPLETTE KONFIGURATION
═══════════════════════════════════════════════════════════════
Weltenbibliothek v3.0.0+84
Project ID: weltenbibliothek-5d21f

Dieses Skript erstellt:
1. Alle Firestore Composite Indexes
2. Optimierte Security Rules
3. Detaillierte Dokumentation
═══════════════════════════════════════════════════════════════
"""

import json
import os

PROJECT_ID = "weltenbibliothek-5d21f"

# ═══════════════════════════════════════════════════════════════
# FIRESTORE COMPOSITE INDEXES
# ═══════════════════════════════════════════════════════════════

FIRESTORE_INDEXES = {
    "indexes": [
        # ───────────────────────────────────────────────────────
        # EVENTS COLLECTION - Hauptdatenbank
        # ───────────────────────────────────────────────────────
        {
            "collectionGroup": "events",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "category", "order": "ASCENDING"},
                {"fieldPath": "date", "order": "DESCENDING"}
            ]
        },
        {
            "collectionGroup": "events",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "category", "order": "ASCENDING"},
                {"fieldPath": "title", "order": "ASCENDING"}
            ]
        },
        {
            "collectionGroup": "events",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "featured", "order": "DESCENDING"},
                {"fieldPath": "date", "order": "DESCENDING"}
            ]
        },
        {
            "collectionGroup": "events",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "category", "order": "ASCENDING"},
                {"fieldPath": "featured", "order": "DESCENDING"},
                {"fieldPath": "date", "order": "DESCENDING"}
            ]
        },
        
        # ───────────────────────────────────────────────────────
        # TELEGRAM MEDIA COLLECTION
        # ───────────────────────────────────────────────────────
        {
            "collectionGroup": "telegram_media",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "category", "order": "ASCENDING"},
                {"fieldPath": "timestamp", "order": "DESCENDING"}
            ]
        },
        {
            "collectionGroup": "telegram_media",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "media_type", "order": "ASCENDING"},
                {"fieldPath": "timestamp", "order": "DESCENDING"}
            ]
        },
        {
            "collectionGroup": "telegram_media",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "category", "order": "ASCENDING"},
                {"fieldPath": "media_type", "order": "ASCENDING"},
                {"fieldPath": "timestamp", "order": "DESCENDING"}
            ]
        },
        
        # ───────────────────────────────────────────────────────
        # CATEGORIES COLLECTION
        # ───────────────────────────────────────────────────────
        {
            "collectionGroup": "categories",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "event_count", "order": "DESCENDING"},
                {"fieldPath": "name", "order": "ASCENDING"}
            ]
        },
        {
            "collectionGroup": "categories",
            "queryScope": "COLLECTION",
            "fields": [
                {"fieldPath": "name", "order": "ASCENDING"},
                {"fieldPath": "event_count", "order": "DESCENDING"}
            ]
        }
    ],
    "fieldOverrides": []
}

# ═══════════════════════════════════════════════════════════════
# FIRESTORE SECURITY RULES
# ═══════════════════════════════════════════════════════════════

FIRESTORE_RULES = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ═══════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════
    
    // Prüft ob Nutzer authentifiziert ist
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Prüft ob Nutzer der Eigentümer ist
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Prüft ob Daten valide sind (nicht leer)
    function isValidData() {
      return request.resource.data.keys().hasAny(['title', 'name', 'content']);
    }
    
    // Prüft ob Zeitstempel gültig ist
    function isValidTimestamp() {
      return request.resource.data.created_at is timestamp;
    }
    
    // ═══════════════════════════════════════════════════════
    // EVENTS COLLECTION
    // Haupt-Datenbank für historische Events
    // ═══════════════════════════════════════════════════════
    match /events/{eventId} {
      // LESEN: Jeder kann Events lesen (auch ohne Auth)
      allow read: if true;
      
      // ERSTELLEN: Nur authentifizierte Nutzer
      allow create: if isSignedIn() 
                    && isValidData()
                    && request.resource.data.keys().hasAll([
                      'title', 'date', 'description', 'category'
                    ]);
      
      // AKTUALISIEREN: Nur Admin oder Eigentümer
      allow update: if isSignedIn() 
                    && (
                      isOwner(resource.data.created_by)
                      || request.auth.token.admin == true
                    );
      
      // LÖSCHEN: Nur Admin
      allow delete: if isSignedIn() 
                    && request.auth.token.admin == true;
    }
    
    // ═══════════════════════════════════════════════════════
    // TELEGRAM MEDIA COLLECTION
    // Telegram Kanal Medien-Bibliothek
    // ═══════════════════════════════════════════════════════
    match /telegram_media/{mediaId} {
      // LESEN: Jeder kann Medien lesen
      allow read: if true;
      
      // ERSTELLEN: Nur authentifizierte Nutzer
      allow create: if isSignedIn()
                    && request.resource.data.keys().hasAll([
                      'title', 'category', 'media_type', 'timestamp'
                    ]);
      
      // AKTUALISIEREN: Nur Admin
      allow update: if isSignedIn() 
                    && request.auth.token.admin == true;
      
      // LÖSCHEN: Nur Admin
      allow delete: if isSignedIn() 
                    && request.auth.token.admin == true;
    }
    
    // ═══════════════════════════════════════════════════════
    // CATEGORIES COLLECTION
    // Kategorien-Verwaltung
    // ═══════════════════════════════════════════════════════
    match /categories/{categoryId} {
      // LESEN: Jeder kann Kategorien lesen
      allow read: if true;
      
      // ERSTELLEN: Nur Admin
      allow create: if isSignedIn() 
                    && request.auth.token.admin == true
                    && request.resource.data.keys().hasAll([
                      'name', 'color', 'icon'
                    ]);
      
      // AKTUALISIEREN: Nur Admin (für event_count Updates)
      allow update: if isSignedIn() 
                    && request.auth.token.admin == true;
      
      // LÖSCHEN: Nur Admin
      allow delete: if isSignedIn() 
                    && request.auth.token.admin == true;
    }
    
    // ═══════════════════════════════════════════════════════
    // USER PREFERENCES (Optional für zukünftige Features)
    // ═══════════════════════════════════════════════════════
    match /users/{userId} {
      // Nur eigene Daten lesen/schreiben
      allow read, write: if isOwner(userId);
    }
    
    // ═══════════════════════════════════════════════════════
    // FAVORITES (Optional für zukünftige Features)
    // ═══════════════════════════════════════════════════════
    match /users/{userId}/favorites/{favoriteId} {
      // Nur eigene Favoriten lesen/schreiben
      allow read, write: if isOwner(userId);
    }
    
    // ═══════════════════════════════════════════════════════
    // DEFAULT DENY (Alle anderen Pfade)
    // ═══════════════════════════════════════════════════════
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
"""

# ═══════════════════════════════════════════════════════════════
# FIRESTORE STORAGE RULES (für Bilder/Dateien)
# ═══════════════════════════════════════════════════════════════

STORAGE_RULES = """rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ═══════════════════════════════════════════════════════
    // EVENT IMAGES
    // ═══════════════════════════════════════════════════════
    match /event_images/{imageId} {
      // LESEN: Jeder kann Bilder sehen
      allow read: if true;
      
      // SCHREIBEN: Nur authentifizierte Nutzer
      // Max 10MB, nur Bilder
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
    
    // ═══════════════════════════════════════════════════════
    // TELEGRAM MEDIA FILES
    // ═══════════════════════════════════════════════════════
    match /telegram_media/{mediaId} {
      // LESEN: Jeder kann Medien sehen
      allow read: if true;
      
      // SCHREIBEN: Nur Admin
      // Max 50MB für Videos/PDFs
      allow write: if request.auth != null
                   && request.auth.token.admin == true
                   && request.resource.size < 50 * 1024 * 1024;
    }
    
    // ═══════════════════════════════════════════════════════
    // USER UPLOADS
    // ═══════════════════════════════════════════════════════
    match /user_uploads/{userId}/{fileName} {
      // Nur eigene Dateien
      allow read, write: if request.auth != null
                         && request.auth.uid == userId
                         && request.resource.size < 5 * 1024 * 1024;
    }
    
    // ═══════════════════════════════════════════════════════
    // DEFAULT DENY
    // ═══════════════════════════════════════════════════════
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
"""

# ═══════════════════════════════════════════════════════════════
# GENERIERE DATEIEN
# ═══════════════════════════════════════════════════════════════

def generate_files():
    """Erstellt alle Firebase Konfigurationsdateien"""
    
    # 1. firestore.indexes.json
    with open('firestore.indexes.json', 'w', encoding='utf-8') as f:
        json.dump(FIRESTORE_INDEXES, f, indent=2, ensure_ascii=False)
    print("✅ firestore.indexes.json erstellt")
    
    # 2. firestore.rules
    with open('firestore.rules', 'w', encoding='utf-8') as f:
        f.write(FIRESTORE_RULES)
    print("✅ firestore.rules erstellt")
    
    # 3. storage.rules
    with open('storage.rules', 'w', encoding='utf-8') as f:
        f.write(STORAGE_RULES)
    print("✅ storage.rules erstellt")
    
    # 4. Deployment Anleitung
    create_deployment_guide()
    
    print("\n" + "═" * 63)
    print("✅ ALLE FIREBASE KONFIGURATIONS-DATEIEN ERSTELLT!")
    print("═" * 63)
    print(f"\n📁 Dateien im Verzeichnis: {os.getcwd()}")
    print("\n📋 Nächste Schritte:")
    print("   1. Lies FIREBASE_DEPLOYMENT_ANLEITUNG.txt")
    print("   2. Installiere Firebase CLI (falls noch nicht vorhanden)")
    print("   3. Deploye Indexes: firebase deploy --only firestore:indexes")
    print("   4. Deploye Rules: firebase deploy --only firestore:rules,storage")
    print("\n" + "═" * 63)

def create_deployment_guide():
    """Erstellt detaillierte Deployment-Anleitung"""
    
    guide = f"""
═══════════════════════════════════════════════════════════════
🔥 FIREBASE DEPLOYMENT ANLEITUNG - SCHRITT FÜR SCHRITT
═══════════════════════════════════════════════════════════════

Project: Weltenbibliothek
Project ID: {PROJECT_ID}
Version: 3.0.0+84

═══════════════════════════════════════════════════════════════
📦 VORAUSSETZUNGEN
═══════════════════════════════════════════════════════════════

1. Firebase CLI installieren:
   npm install -g firebase-tools

2. Firebase Login:
   firebase login

3. Projekt initialisieren (falls noch nicht gemacht):
   firebase init

   Wähle:
   - Firestore: Configure security rules and indexes
   - Storage: Configure storage rules

4. Stelle sicher, dass .firebaserc existiert mit:
   {{
     "projects": {{
       "default": "{PROJECT_ID}"
     }}
   }}

═══════════════════════════════════════════════════════════════
🚀 DEPLOYMENT BEFEHLE
═══════════════════════════════════════════════════════════════

▶ OPTION 1: Alles auf einmal deployen
─────────────────────────────────────────────────────────────
firebase deploy --only firestore,storage

▶ OPTION 2: Einzeln deployen
─────────────────────────────────────────────────────────────
# Nur Firestore Indexes
firebase deploy --only firestore:indexes

# Nur Firestore Security Rules
firebase deploy --only firestore:rules

# Nur Storage Rules
firebase deploy --only storage

▶ OPTION 3: Dry-Run (Testen ohne Deployment)
─────────────────────────────────────────────────────────────
firebase deploy --only firestore:rules --dry-run

═══════════════════════════════════════════════════════════════
📋 FIRESTORE INDEXES DETAILS
═══════════════════════════════════════════════════════════════

Die folgenden Composite Indexes werden erstellt:

┌─────────────────────────────────────────────────────────────┐
│ EVENTS COLLECTION (4 Indexes)                               │
└─────────────────────────────────────────────────────────────┘

1. Index: category (ASC) + date (DESC)
   Query: Events nach Kategorie, sortiert nach Datum
   Beispiel: .where('category', '==', 'ufos')
             .orderBy('date', 'desc')

2. Index: category (ASC) + title (ASC)
   Query: Events nach Kategorie, alphabetisch sortiert
   Beispiel: .where('category', '==', 'ufos')
             .orderBy('title', 'asc')

3. Index: featured (DESC) + date (DESC)
   Query: Featured Events, sortiert nach Datum
   Beispiel: .where('featured', '==', true)
             .orderBy('date', 'desc')

4. Index: category (ASC) + featured (DESC) + date (DESC)
   Query: Featured Events pro Kategorie
   Beispiel: .where('category', '==', 'ufos')
             .where('featured', '==', true)
             .orderBy('date', 'desc')

┌─────────────────────────────────────────────────────────────┐
│ TELEGRAM_MEDIA COLLECTION (3 Indexes)                       │
└─────────────────────────────────────────────────────────────┘

1. Index: category (ASC) + timestamp (DESC)
   Query: Medien nach Kategorie, neueste zuerst
   Beispiel: .where('category', '==', 'videos')
             .orderBy('timestamp', 'desc')

2. Index: media_type (ASC) + timestamp (DESC)
   Query: Medien nach Typ (video/document/audio)
   Beispiel: .where('media_type', '==', 'video')
             .orderBy('timestamp', 'desc')

3. Index: category (ASC) + media_type (ASC) + timestamp (DESC)
   Query: Medien nach Kategorie UND Typ
   Beispiel: .where('category', '==', 'ufos')
             .where('media_type', '==', 'video')
             .orderBy('timestamp', 'desc')

┌─────────────────────────────────────────────────────────────┐
│ CATEGORIES COLLECTION (2 Indexes)                           │
└─────────────────────────────────────────────────────────────┘

1. Index: event_count (DESC) + name (ASC)
   Query: Kategorien nach Anzahl Events sortiert
   Beispiel: .orderBy('event_count', 'desc')
             .orderBy('name', 'asc')

2. Index: name (ASC) + event_count (DESC)
   Query: Kategorien alphabetisch mit Event-Count
   Beispiel: .orderBy('name', 'asc')
             .orderBy('event_count', 'desc')

═══════════════════════════════════════════════════════════════
🔐 SECURITY RULES ÜBERSICHT
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│ EVENTS COLLECTION                                            │
└─────────────────────────────────────────────────────────────┘
• Lesen: Jeder (auch ohne Auth)
• Erstellen: Nur authentifizierte Nutzer
• Aktualisieren: Nur Eigentümer oder Admin
• Löschen: Nur Admin

┌─────────────────────────────────────────────────────────────┐
│ TELEGRAM_MEDIA COLLECTION                                   │
└─────────────────────────────────────────────────────────────┘
• Lesen: Jeder (auch ohne Auth)
• Erstellen: Nur authentifizierte Nutzer
• Aktualisieren: Nur Admin
• Löschen: Nur Admin

┌─────────────────────────────────────────────────────────────┐
│ CATEGORIES COLLECTION                                        │
└─────────────────────────────────────────────────────────────┘
• Lesen: Jeder (auch ohne Auth)
• Erstellen: Nur Admin
• Aktualisieren: Nur Admin
• Löschen: Nur Admin

┌─────────────────────────────────────────────────────────────┐
│ STORAGE (Bilder/Dateien)                                     │
└─────────────────────────────────────────────────────────────┘

event_images/: 
  • Lesen: Jeder
  • Schreiben: Authentifizierte Nutzer (max 10MB, nur Bilder)

telegram_media/:
  • Lesen: Jeder
  • Schreiben: Nur Admin (max 50MB)

user_uploads/:
  • Lesen/Schreiben: Nur eigener Account (max 5MB)

═══════════════════════════════════════════════════════════════
🧪 TESTING DER RULES
═══════════════════════════════════════════════════════════════

1. In Firebase Console:
   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/rules

2. Klicke auf "Rules Playground"

3. Teste verschiedene Szenarien:
   
   ✅ Test 1: Event lesen (ohne Auth)
   Operation: get
   Location: /events/event_001
   Auth: Not signed in
   → Sollte ERLAUBT sein

   ✅ Test 2: Event erstellen (mit Auth)
   Operation: create
   Location: /events/new_event
   Auth: Authenticated user (test@example.com)
   → Sollte ERLAUBT sein

   ❌ Test 3: Event löschen (ohne Admin)
   Operation: delete
   Location: /events/event_001
   Auth: Regular user
   → Sollte VERWEIGERT werden

═══════════════════════════════════════════════════════════════
⚠️ WICHTIGE HINWEISE
═══════════════════════════════════════════════════════════════

1. INDEX ERSTELLUNG DAUERT
   • Indexes werden asynchron erstellt
   • Kann 5-15 Minuten dauern
   • Status prüfen in Firebase Console

2. BACKUP VOR DEPLOYMENT
   • Sichere aktuelle Rules falls nötig
   • Firestore Export für Sicherheit:
     gcloud firestore export gs://{PROJECT_ID}.appspot.com/backup

3. ENTWICKLUNG vs PRODUKTION
   • Aktuelle Rules sind ENTWICKLUNGSFREUNDLICH
   • Für Produktion: Strengere Rules implementieren
   • Admin-Rechte über Custom Claims setzen

4. ADMIN CUSTOM CLAIMS
   Setze Admin-Rechte für Nutzer:
   
   firebase auth:import --hash-algo=SCRYPT users.json
   
   Oder via Admin SDK:
   admin.auth().setCustomUserClaims(uid, {{admin: true}})

═══════════════════════════════════════════════════════════════
📊 MONITORING & ANALYTICS
═══════════════════════════════════════════════════════════════

1. Firestore Usage Dashboard:
   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/usage

2. Security Rules Monitoring:
   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/rules

3. Query Performance:
   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/data

═══════════════════════════════════════════════════════════════
🔧 TROUBLESHOOTING
═══════════════════════════════════════════════════════════════

Problem: "Index not found" Error
Lösung: Warte 5-15 Minuten nach Deployment
        Prüfe Status in Firebase Console

Problem: "Permission denied" Error
Lösung: Prüfe Authentication Status
        Verifiziere Rules in Rules Playground

Problem: Deployment schlägt fehl
Lösung: firebase login --reauth
        Prüfe .firebaserc Konfiguration

═══════════════════════════════════════════════════════════════
📞 SUPPORT & DOKUMENTATION
═══════════════════════════════════════════════════════════════

Firebase Dokumentation:
https://firebase.google.com/docs/firestore

Security Rules Guide:
https://firebase.google.com/docs/firestore/security/get-started

Indexes Guide:
https://firebase.google.com/docs/firestore/query-data/indexing

Firebase CLI Referenz:
https://firebase.google.com/docs/cli

═══════════════════════════════════════════════════════════════
✅ DEPLOYMENT CHECKLIST
═══════════════════════════════════════════════════════════════

□ Firebase CLI installiert
□ firebase login erfolgreich
□ .firebaserc existiert mit richtigem Project ID
□ firestore.indexes.json überprüft
□ firestore.rules überprüft
□ storage.rules überprüft
□ Backup der aktuellen Rules erstellt
□ firebase deploy --only firestore:indexes ausgeführt
□ firebase deploy --only firestore:rules ausgeführt
□ firebase deploy --only storage ausgeführt
□ Index-Erstellung in Console überwacht (5-15 Min)
□ Rules im Rules Playground getestet
□ App getestet mit neuen Rules

═══════════════════════════════════════════════════════════════
🎉 ERFOLGREICHES DEPLOYMENT!
═══════════════════════════════════════════════════════════════

Nach erfolgreichem Deployment:

1. ✅ Alle Indexes sind erstellt und aktiv
2. ✅ Security Rules sind deployed
3. ✅ Storage Rules sind deployed
4. ✅ App funktioniert mit optimierten Queries
5. ✅ Sicherheit ist gewährleistet

Die Weltenbibliothek ist jetzt produktionsbereit! 🚀

═══════════════════════════════════════════════════════════════
"""
    
    with open('FIREBASE_DEPLOYMENT_ANLEITUNG.txt', 'w', encoding='utf-8') as f:
        f.write(guide)
    print("✅ FIREBASE_DEPLOYMENT_ANLEITUNG.txt erstellt")

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

if __name__ == '__main__':
    print("\n" + "═" * 63)
    print("🔥 FIREBASE SETUP - WELTENBIBLIOTHEK v3.0.0+84")
    print("═" * 63)
    print(f"\nProject ID: {PROJECT_ID}")
    print("\nGeneriere Firebase Konfigurationsdateien...\n")
    
    generate_files()

