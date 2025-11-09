#!/usr/bin/env python3
"""
Weltenbibliothek - Vollautomatisches Firestore-Setup
====================================================
Installiert ALLE Firestore-Regeln und Indexes mit einem Klick

Verwendung:
    python3 auto_setup_firestore_complete.py
"""

import json
import subprocess
import sys
import time
from datetime import datetime

# Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud import firestore_admin_v1
    from google.cloud.firestore_admin_v1 import Index, IndexField
except ImportError:
    print("❌ Fehler: firebase-admin nicht installiert")
    print("📦 Installation: pip3 install firebase-admin google-cloud-firestore")
    sys.exit(1)

# Konfiguration
FIREBASE_ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"
PROJECT_ID = "weltenbibliothek-5d21f"

# ANSI Color Codes
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"


def print_header(title):
    """Druckt formatierten Header"""
    print(f"\n{BLUE}{'=' * 70}{RESET}")
    print(f"{BLUE}{title.center(70)}{RESET}")
    print(f"{BLUE}{'=' * 70}{RESET}\n")


def print_success(message):
    """Erfolgs-Nachricht"""
    print(f"{GREEN}✅ {message}{RESET}")


def print_error(message):
    """Fehler-Nachricht"""
    print(f"{RED}❌ {message}{RESET}")


def print_warning(message):
    """Warnung"""
    print(f"{YELLOW}⚠️  {message}{RESET}")


def print_info(message):
    """Info-Nachricht"""
    print(f"{BLUE}ℹ️  {message}{RESET}")


def initialize_firebase():
    """Initialisiert Firebase Admin SDK"""
    try:
        print_info("Initialisiere Firebase Admin SDK...")
        cred = credentials.Certificate(FIREBASE_ADMIN_SDK_PATH)
        firebase_admin.initialize_app(cred, {
            'projectId': PROJECT_ID
        })
        print_success("Firebase Admin SDK initialisiert")
        return firestore.client()
    except Exception as e:
        print_error(f"Firebase-Initialisierung fehlgeschlagen: {e}")
        sys.exit(1)


def get_complete_firestore_rules():
    """
    Gibt die KOMPLETTEN Firestore Security Rules zurück
    Enthält ALLE Collections und ALLE Regeln der App
    """
    return """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // HILFSFUNKTIONEN (Gemeinsam verwendet)
    // ============================================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // ============================================
    // BENUTZER-VERWALTUNG (users)
    // ============================================
    match /users/{userId} {
      // Lesen: Authentifizierte Benutzer können alle Profile lesen
      allow read: if isAuthenticated();
      
      // Erstellen: Nur eigenes Profil beim Signup
      allow create: if isAuthenticated() && request.auth.uid == userId;
      
      // Aktualisieren: Nur eigenes Profil oder Admin
      allow update: if isOwner(userId) || isAdmin();
      
      // Löschen: Nur Admin
      allow delete: if isAdmin();
    }
    
    // ============================================
    // BIBLIOTHEKS-EINTRÄGE (library_items)
    // ============================================
    match /library_items/{itemId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Einträge oder Admin
      allow update: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
      
      // Löschen: Eigene Einträge oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // CHAT-NACHRICHTEN (chat_messages)
    // ============================================
    match /chat_messages/{messageId} {
      // Lesen: Alle authentifizierten Benutzer
      // (Öffentlicher Chat @Weltenbibliothekchat)
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer (eigene Nachrichten)
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.source == 'app';
      
      // Aktualisieren: Eigene Nachrichten (für Bearbeitung)
      allow update: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || 
                       resource.data.source == 'telegram');
      
      // Löschen: Eigene Nachrichten oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // KOMMENTARE (comments)
    // ============================================
    match /comments/{commentId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Kommentare
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      
      // Löschen: Eigene Kommentare oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // VERANSTALTUNGEN (events)
    // ============================================
    match /events/{eventId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Admin oder Event-Creator
      allow create: if isAuthenticated() && 
                      (isAdmin() || request.resource.data.creatorId == request.auth.uid);
      
      // Aktualisieren: Event-Creator oder Admin
      allow update: if isAuthenticated() && 
                      (resource.data.creatorId == request.auth.uid || isAdmin());
      
      // Löschen: Event-Creator oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.creatorId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // BENACHRICHTIGUNGEN (notifications)
    // ============================================
    match /notifications/{notificationId} {
      // Lesen: Nur eigene Benachrichtigungen
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      // Erstellen: System oder Admin
      allow create: if isAdmin();
      
      // Aktualisieren: Nur read-Status ändern (für "gelesen")
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid &&
                      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      
      // Löschen: Eigene Benachrichtigungen
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
    }
    
    // ============================================
    // BOOKMARKS (bookmarks)
    // ============================================
    match /bookmarks/{bookmarkId} {
      // Lesen: Nur eigene Bookmarks
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      // Erstellen: Eigene Bookmarks
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Bookmarks
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      
      // Löschen: Eigene Bookmarks
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
    }
    
    // ============================================
    // SYSTEM-EINSTELLUNGEN (settings)
    // ============================================
    match /settings/{settingId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Schreiben: Nur Admin
      allow write: if isAdmin();
    }
    
    // ============================================
    // FALLBACK-REGEL (Deny All)
    // ============================================
    // Alle anderen Pfade sind standardmäßig blockiert
    match /{document=**} {
      allow read, write: if false;
    }
  }
}"""


def deploy_firestore_rules(db):
    """
    Deployed Firestore Security Rules über Firebase CLI
    """
    print_header("FIRESTORE SECURITY RULES DEPLOYMENT")
    
    try:
        # Rules in temporäre Datei schreiben
        rules_file = "/tmp/firestore.rules"
        with open(rules_file, 'w') as f:
            f.write(get_complete_firestore_rules())
        
        print_info(f"Rules-Datei erstellt: {rules_file}")
        print_info("Deploying Rules via Firebase CLI...")
        
        # Firebase CLI verwenden (falls installiert)
        try:
            result = subprocess.run(
                ["firebase", "deploy", "--only", "firestore:rules", "--project", PROJECT_ID],
                cwd="/home/user/flutter_app",
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                print_success("Firestore Rules erfolgreich deployed!")
                print_info(result.stdout)
                return True
            else:
                print_warning("Firebase CLI-Deployment fehlgeschlagen")
                print_info("Verwende alternativen Ansatz...")
        except FileNotFoundError:
            print_warning("Firebase CLI nicht gefunden")
            print_info("Verwende REST API...")
        except Exception as e:
            print_warning(f"Firebase CLI-Fehler: {e}")
        
        # Alternative: REST API (erfordert manuelles Setup)
        print_info("\n📋 MANUELLE INSTALLATION ERFORDERLICH:")
        print_info("=" * 70)
        print(f"\n1. Öffnen Sie die Firebase Console:")
        print(f"   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/rules\n")
        print(f"2. Kopieren Sie die Rules aus: {rules_file}")
        print(f"3. Ersetzen Sie den kompletten Inhalt im Editor")
        print(f"4. Klicken Sie auf 'Veröffentlichen'\n")
        
        print_info("Rules-Datei Inhalt:")
        print(f"{BLUE}{'─' * 70}{RESET}")
        print(get_complete_firestore_rules())
        print(f"{BLUE}{'─' * 70}{RESET}\n")
        
        return False
        
    except Exception as e:
        print_error(f"Rules-Deployment fehlgeschlagen: {e}")
        return False


def create_composite_indexes():
    """
    Erstellt ALLE Composite Indexes für die Weltenbibliothek
    """
    print_header("FIRESTORE COMPOSITE INDEXES ERSTELLEN")
    
    try:
        # Firestore Admin Client initialisieren
        client = firestore_admin_v1.FirestoreAdminClient()
        parent = f"projects/{PROJECT_ID}/databases/(default)/collectionGroups/chat_messages"
        
        # Index-Definitionen
        indexes = [
            {
                "name": "App → Telegram Sync",
                "fields": [
                    {"field_path": "source", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "syncedToTelegram", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "__name__", "order": Index.IndexField.Order.ASCENDING}
                ]
            },
            {
                "name": "Chat Display (Flutter)",
                "fields": [
                    {"field_path": "deleted", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "timestamp", "order": Index.IndexField.Order.DESCENDING},
                    {"field_path": "__name__", "order": Index.IndexField.Order.ASCENDING}
                ]
            },
            {
                "name": "Edit Sync",
                "fields": [
                    {"field_path": "source", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "edited", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "editSyncedToTelegram", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "__name__", "order": Index.IndexField.Order.ASCENDING}
                ]
            },
            {
                "name": "Delete Sync",
                "fields": [
                    {"field_path": "source", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "deleted", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "deleteSyncedToTelegram", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "__name__", "order": Index.IndexField.Order.ASCENDING}
                ]
            },
            {
                "name": "Auto-Delete (24h)",
                "fields": [
                    {"field_path": "timestamp", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "deleted", "order": Index.IndexField.Order.ASCENDING},
                    {"field_path": "__name__", "order": Index.IndexField.Order.ASCENDING}
                ]
            }
        ]
        
        print_info(f"Erstelle {len(indexes)} Composite Indexes...")
        print_info(f"Parent: {parent}\n")
        
        created_count = 0
        failed_count = 0
        
        for idx_def in indexes:
            try:
                print_info(f"Index: {idx_def['name']}")
                
                # Index-Objekt erstellen
                index = Index(
                    query_scope=Index.QueryScope.COLLECTION,
                    fields=[
                        Index.IndexField(
                            field_path=field["field_path"],
                            order=field["order"]
                        ) for field in idx_def["fields"]
                    ]
                )
                
                # Index erstellen (Long-Running Operation)
                operation = client.create_index(
                    request={
                        "parent": parent,
                        "index": index
                    }
                )
                
                print_info(f"  → Operation gestartet: {operation.operation.name}")
                print_info(f"  → Warte auf Abschluss (kann 5-15 Minuten dauern)...")
                
                # Warten auf Abschluss (mit Timeout)
                result = operation.result(timeout=900)  # 15 Minuten Timeout
                
                print_success(f"  ✓ Index erfolgreich erstellt!")
                print_info(f"  → Index Name: {result.name}\n")
                created_count += 1
                
            except Exception as e:
                error_str = str(e)
                
                # Bereits existierende Indexes ignorieren
                if "ALREADY_EXISTS" in error_str or "already exists" in error_str.lower():
                    print_warning(f"  → Index existiert bereits")
                    created_count += 1
                else:
                    print_error(f"  → Fehler: {e}")
                    failed_count += 1
        
        print(f"\n{BLUE}{'─' * 70}{RESET}")
        print_success(f"Indexes erfolgreich: {created_count}/{len(indexes)}")
        if failed_count > 0:
            print_warning(f"Indexes fehlgeschlagen: {failed_count}/{len(indexes)}")
        print(f"{BLUE}{'─' * 70}{RESET}\n")
        
        # Alternative: Manuelle Installation via Console
        if failed_count > 0:
            print_info("\n📋 ALTERNATIVE: MANUELLE INDEX-ERSTELLUNG")
            print_info("=" * 70)
            print(f"\nFalls automatische Erstellung fehlschlägt:")
            print(f"\n1. Starten Sie den Chat-Sync-Daemon:")
            print(f"   sudo systemctl start telegram-chat-sync")
            print(f"\n2. Beobachten Sie die Logs:")
            print(f"   tail -f /var/log/telegram-chat-sync.log")
            print(f"\n3. Firebase zeigt automatisch Index-URLs bei Fehlern:")
            print(f"   https://console.firebase.google.com/project/{PROJECT_ID}/firestore/indexes?create_composite=...")
            print(f"\n4. Klicken Sie auf die URLs → Indexes werden automatisch erstellt\n")
        
        return created_count, failed_count
        
    except Exception as e:
        print_error(f"Index-Erstellung fehlgeschlagen: {e}")
        print_info("\n📋 MANUELLE INSTALLATION (Fallback):")
        print_info("=" * 70)
        print(f"\nFirebase Console: https://console.firebase.google.com/project/{PROJECT_ID}/firestore/indexes\n")
        print("Erstellen Sie folgende Indexes manuell:\n")
        
        print("Index 1: App → Telegram Sync")
        print("  Collection: chat_messages")
        print("  Fields: source (ASC), syncedToTelegram (ASC), __name__ (ASC)\n")
        
        print("Index 2: Chat Display")
        print("  Collection: chat_messages")
        print("  Fields: deleted (ASC), timestamp (DESC), __name__ (ASC)\n")
        
        print("Index 3: Edit Sync")
        print("  Collection: chat_messages")
        print("  Fields: source (ASC), edited (ASC), editSyncedToTelegram (ASC), __name__ (ASC)\n")
        
        print("Index 4: Delete Sync")
        print("  Collection: chat_messages")
        print("  Fields: source (ASC), deleted (ASC), deleteSyncedToTelegram (ASC), __name__ (ASC)\n")
        
        print("Index 5: Auto-Delete")
        print("  Collection: chat_messages")
        print("  Fields: timestamp (ASC), deleted (ASC), __name__ (ASC)\n")
        
        return 0, 5


def main():
    """Hauptfunktion"""
    print_header("WELTENBIBLIOTHEK - FIRESTORE VOLLAUTOMATISCHES SETUP")
    print_info(f"Datum: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_info(f"Projekt: {PROJECT_ID}")
    print_info(f"Admin SDK: {FIREBASE_ADMIN_SDK_PATH}\n")
    
    # Firebase initialisieren
    db = initialize_firebase()
    
    # Schritt 1: Security Rules deployen
    rules_success = deploy_firestore_rules(db)
    
    # Schritt 2: Composite Indexes erstellen
    created, failed = create_composite_indexes()
    
    # Zusammenfassung
    print_header("SETUP-ZUSAMMENFASSUNG")
    
    if rules_success:
        print_success("Firestore Security Rules: Deployed")
    else:
        print_warning("Firestore Security Rules: Manuelle Installation erforderlich")
    
    print_info(f"Composite Indexes: {created} erstellt, {failed} fehlgeschlagen")
    
    if rules_success and failed == 0:
        print_success("\n🎉 VOLLAUTOMATISCHES SETUP ERFOLGREICH ABGESCHLOSSEN!")
        print_info("Die Weltenbibliothek ist jetzt produktionsbereit.")
    else:
        print_warning("\n⚠️  SETUP TEILWEISE ERFOLGREICH")
        print_info("Bitte folgen Sie den manuellen Installations-Anweisungen oben.")
    
    print(f"\n{BLUE}{'=' * 70}{RESET}\n")
    
    # Firebase Console Link
    print_info("📋 Firebase Console URLs:")
    print(f"   Rules: https://console.firebase.google.com/project/{PROJECT_ID}/firestore/rules")
    print(f"   Indexes: https://console.firebase.google.com/project/{PROJECT_ID}/firestore/indexes")
    print(f"   Data: https://console.firebase.google.com/project/{PROJECT_ID}/firestore/data\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print_error("\n\nSetup abgebrochen durch Benutzer")
        sys.exit(1)
    except Exception as e:
        print_error(f"\n\nUnerwarteter Fehler: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
