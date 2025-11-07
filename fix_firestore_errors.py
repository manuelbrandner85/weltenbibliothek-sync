#!/usr/bin/env python3
"""
Firestore Security Rules & Indexes Fixer
Behebt Permission-Denied und Missing-Index Fehler
"""

import os
import sys

# Firestore Security Rules (Development-freundlich)
SECURITY_RULES = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Telegram Collections - Public Read, Authenticated Write
    match /telegram_videos/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /telegram_photos/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /telegram_documents/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /telegram_audio/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /telegram_feed/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /telegram_messages/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Live Chat Collections
    match /live_chat_messages/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /live_chat_participants/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User Collections
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Config Collections
    match /telegram_config/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Default - Authenticated only
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
"""

# Firestore Indexes (für komplexe Queries)
FIRESTORE_INDEXES = """
BENÖTIGTE COMPOSITE INDEXES:

1. Collection: telegram_videos
   Fields: 
   - topic (Ascending)
   - timestamp (Descending)
   
2. Collection: telegram_messages
   Fields:
   - is_pinned (Ascending)
   - pinned_at (Descending)
   
3. Collection: telegram_messages
   Fields:
   - favorite_by (Array)
   - timestamp (Descending)
   
4. Collection: telegram_messages
   Fields:
   - thread_id (Ascending)
   - timestamp (Ascending)

AUTOMATISCHE INDEX-ERSTELLUNG:
Die Links werden automatisch in den Fehlermeldungen angezeigt.
Klicke auf die Links in der Firebase Console, um Indexes zu erstellen.

MANUELLE ERSTELLUNG:
1. Gehe zu: https://console.firebase.google.com/
2. Wähle dein Projekt: weltenbibliothek-5d21f
3. Navigiere zu: Firestore Database → Indexes
4. Klicke auf: "Create Index"
5. Konfiguriere wie oben angegeben
"""

def print_security_rules():
    """Gibt die Firestore Security Rules aus"""
    print("=" * 80)
    print("🔐 FIRESTORE SECURITY RULES")
    print("=" * 80)
    print()
    print("Diese Rules müssen in der Firebase Console eingetragen werden:")
    print()
    print(SECURITY_RULES)
    print()
    print("=" * 80)
    print()

def print_index_guide():
    """Gibt die Index-Anleitung aus"""
    print("=" * 80)
    print("📊 FIRESTORE INDEXES")
    print("=" * 80)
    print()
    print(FIRESTORE_INDEXES)
    print()
    print("=" * 80)
    print()

def print_manual_steps():
    """Gibt manuelle Schritte aus"""
    print("=" * 80)
    print("📋 MANUELLE SCHRITTE")
    print("=" * 80)
    print()
    print("SCHRITT 1: Security Rules setzen")
    print("-" * 40)
    print("1. Öffne: https://console.firebase.google.com/")
    print("2. Projekt: weltenbibliothek-5d21f")
    print("3. Gehe zu: Firestore Database → Rules")
    print("4. Ersetze den Inhalt mit den oben gezeigten Rules")
    print("5. Klicke auf: 'Publish'")
    print()
    print("SCHRITT 2: Indexes erstellen")
    print("-" * 40)
    print("OPTION A - Automatisch (empfohlen):")
    print("1. Öffne die App und gehe zu 'Telegram-Archiv' → 'Videos'")
    print("2. Filtere nach 'Verlorene Zivilisationen'")
    print("3. Der Fehler zeigt einen Link zur Index-Erstellung")
    print("4. Klicke auf den Link und bestätige")
    print()
    print("OPTION B - Manuell:")
    print("1. Gehe zu: Firestore Database → Indexes")
    print("2. Klicke auf: 'Create Index'")
    print("3. Konfiguriere wie oben in der Index-Liste")
    print("4. Wiederhole für alle 4 Indexes")
    print()
    print("=" * 80)
    print()

def print_quick_fix():
    """Gibt Quick-Fix-Anleitung aus"""
    print()
    print("⚡ QUICK FIX - Für sofortige Funktionalität:")
    print("=" * 80)
    print()
    print("1. Öffne Firebase Console:")
    print("   https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules")
    print()
    print("2. Ersetze ALLE Rules mit diesem einfachen Rule-Set:")
    print()
    print("-" * 80)
    print("rules_version = '2';")
    print("service cloud.firestore {")
    print("  match /databases/{database}/documents {")
    print("    match /{document=**} {")
    print("      allow read, write: if true;")
    print("    }")
    print("  }")
    print("}")
    print("-" * 80)
    print()
    print("⚠️  WARNUNG: Dies erlaubt JEDEM Zugriff auf deine Daten!")
    print("   Nur für Development/Testing verwenden!")
    print()
    print("3. Klicke auf 'Publish'")
    print()
    print("4. Warte 30 Sekunden und starte die App neu")
    print()
    print("=" * 80)
    print()

def main():
    print()
    print("🔧 WELTENBIBLIOTHEK V2.14.4 - FIRESTORE ERROR FIXER")
    print("=" * 80)
    print()
    
    # Print Quick Fix first
    print_quick_fix()
    
    # Print Security Rules
    print_security_rules()
    
    # Print Index Guide
    print_index_guide()
    
    # Print Manual Steps
    print_manual_steps()
    
    print()
    print("✅ Fertig! Befolge die Schritte oben, um die Fehler zu beheben.")
    print()

if __name__ == "__main__":
    main()
