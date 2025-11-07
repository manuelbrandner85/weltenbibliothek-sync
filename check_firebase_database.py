#!/usr/bin/env python3
"""
Firebase Database Existenz Prüfer
Überprüft ob eine Firestore Database existiert und zeigt den Status an.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def check_firestore_database():
    """Prüft ob eine Firestore Database existiert"""
    
    print("=" * 70)
    print("🔍 FIREBASE DATABASE EXISTENZ CHECK")
    print("=" * 70)
    
    try:
        # Admin SDK initialisieren
        cred_path = '/opt/flutter/firebase-admin-sdk.json'
        print(f"\n📂 Lade Firebase Admin SDK: {cred_path}")
        
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK erfolgreich initialisiert")
        
        # Firestore Client erstellen
        print("\n🔗 Verbinde zu Firestore...")
        db = firestore.client()
        
        # Test-Abfrage ausführen um zu prüfen ob Database existiert
        print("📊 Führe Test-Abfrage aus...")
        
        # Versuche eine Collection zu lesen
        collections = db.collections()
        collection_names = [col.id for col in collections]
        
        if collection_names:
            print("\n✅ FIRESTORE DATABASE EXISTIERT!")
            print(f"📚 Gefundene Collections: {len(collection_names)}")
            print("\nCollections:")
            for name in collection_names:
                doc_count = len(list(db.collection(name).limit(1).stream()))
                print(f"   - {name} {'(hat Dokumente)' if doc_count > 0 else '(leer)'}")
        else:
            print("\n⚠️  FIRESTORE DATABASE EXISTIERT, ABER IST LEER!")
            print("Keine Collections gefunden.")
            
        # Teste eine spezifische Abfrage
        print("\n🧪 Teste spezifische Abfrage (telegram_messages)...")
        try:
            test_query = db.collection('telegram_messages').limit(1).get()
            if test_query:
                print("✅ telegram_messages Collection ist erreichbar")
            else:
                print("⚠️  telegram_messages Collection ist leer")
        except Exception as e:
            print(f"❌ telegram_messages Collection Fehler: {e}")
            
        print("\n" + "=" * 70)
        print("✅ DATABASE CHECK ABGESCHLOSSEN")
        print("=" * 70)
        
        return True
        
    except Exception as e:
        error_message = str(e).lower()
        
        print("\n" + "=" * 70)
        print("❌ KRITISCHER FEHLER!")
        print("=" * 70)
        
        if 'not found' in error_message or 'does not exist' in error_message:
            print("\n🚨 FIRESTORE DATABASE EXISTIERT NICHT!")
            print("\nDu musst zuerst eine Firestore Database erstellen:")
            print("\n1. Gehe zu: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore")
            print("2. Klicke auf 'Create database' oder 'Datenbank erstellen'")
            print("3. Wähle einen Standort (z.B. 'europe-west')")
            print("4. Wähle 'Production mode' oder 'Test mode'")
            print("5. Warte bis die Database erstellt ist (~30 Sekunden)")
            print("\n⚠️  OHNE DATABASE FUNKTIONIERT DIE APP NICHT!")
            
        elif 'permission' in error_message or 'credentials' in error_message:
            print("\n🚨 BERECHTIGUNGS-PROBLEM!")
            print("Das Admin SDK hat keine Berechtigung.")
            print("Prüfe ob die Admin SDK Datei korrekt ist.")
            
        else:
            print(f"\n🚨 UNBEKANNTER FEHLER:")
            print(f"   {e}")
            
        print("\n" + "=" * 70)
        return False

if __name__ == '__main__':
    try:
        success = check_firestore_database()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Abgebrochen durch Benutzer")
        sys.exit(1)
