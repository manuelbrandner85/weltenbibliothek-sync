#!/usr/bin/env python3
"""
🔥 MULTI-CHANNEL FIRESTORE COLLECTIONS SETUP
============================================

Erstellt Firestore Collections für alle 6 Telegram-Kanäle
mit passenden Indexes und Security Rules.
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("\n╔════════════════════════════════════════════════════════════╗")
print("║  🔥 MULTI-CHANNEL FIRESTORE SETUP                        ║")
print("║     6 Collections für Telegram-Kanäle                    ║")
print("╚════════════════════════════════════════════════════════════╝\n")

# Collection Definitions
COLLECTIONS = [
    {
        'name': 'chat_messages',
        'channel': '@Weltenbibliothekchat',
        'description': 'Chat-Nachrichten (Text, Medien)',
        'sample_data': {
            'messageId': '1',
            'text': 'Willkommen im Chat!',
            'source': 'telegram',
            'channel': 'Chat',
            'channelUsername': '@Weltenbibliothekchat',
            'telegramUserId': '123456',
            'telegramUsername': 'test_user',
            'telegramFirstName': 'Test',
            'telegramLastName': 'User',
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'mediaUrl': None,
            'mediaType': None,
            'ftpPath': None,
            'replyToId': None,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
    {
        'name': 'pdf_documents',
        'channel': '@WeltenbibliothekPDF',
        'description': 'PDF-Dokumente und Bücher',
        'sample_data': {
            'messageId': '1',
            'text': 'Neues PDF-Buch verfügbar',
            'source': 'telegram',
            'channel': 'PDFs',
            'channelUsername': '@WeltenbibliothekPDF',
            'telegramUserId': '123456',
            'title': 'Beispiel-Buch',
            'author': 'Unbekannt',
            'mediaUrl': None,
            'mediaType': 'document',
            'ftpPath': '/pdfs/document_1.pdf',
            'fileSize': 0,
            'pages': 0,
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
    {
        'name': 'images',
        'channel': '@weltenbibliothekbilder',
        'description': 'Bilder und Fotos',
        'sample_data': {
            'messageId': '1',
            'text': 'Neues Bild hochgeladen',
            'source': 'telegram',
            'channel': 'Bilder',
            'channelUsername': '@weltenbibliothekbilder',
            'telegramUserId': '123456',
            'caption': 'Beispielbild',
            'mediaUrl': None,
            'mediaType': 'photo',
            'ftpPath': '/images/photo_1.jpg',
            'width': 0,
            'height': 0,
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
    {
        'name': 'wachauf_content',
        'channel': '@WeltenbibliothekWachauf',
        'description': 'Wachauf-Inhalte',
        'sample_data': {
            'messageId': '1',
            'text': 'Neuer Wachauf-Beitrag',
            'source': 'telegram',
            'channel': 'Wachauf',
            'channelUsername': '@WeltenbibliothekWachauf',
            'telegramUserId': '123456',
            'category': 'Aufklärung',
            'mediaUrl': None,
            'mediaType': None,
            'ftpPath': None,
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
    {
        'name': 'archive_items',
        'channel': '@ArchivWeltenBibliothek',
        'description': 'Archiv-Einträge',
        'sample_data': {
            'messageId': '1',
            'text': 'Neuer Archiv-Eintrag',
            'source': 'telegram',
            'channel': 'Archiv',
            'channelUsername': '@ArchivWeltenBibliothek',
            'telegramUserId': '123456',
            'archiveCategory': 'Historisch',
            'mediaUrl': None,
            'mediaType': None,
            'ftpPath': None,
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
    {
        'name': 'audiobooks',
        'channel': '@WeltenbibliothekHoerbuch',
        'description': 'Hörbücher',
        'sample_data': {
            'messageId': '1',
            'text': 'Neues Hörbuch verfügbar',
            'source': 'telegram',
            'channel': 'Hörbücher',
            'channelUsername': '@WeltenbibliothekHoerbuch',
            'telegramUserId': '123456',
            'title': 'Beispiel-Hörbuch',
            'author': 'Unbekannt',
            'narrator': 'Unbekannt',
            'duration': 0,
            'mediaUrl': None,
            'mediaType': 'audio',
            'ftpPath': '/audios/audio_1.mp3',
            'edited': False,
            'deleted': False,
            'syncedToTelegram': True,
            'timestamp': firestore.SERVER_TIMESTAMP,
        }
    },
]

print("📦 Erstelle Collections mit Sample-Daten...\n")

for coll in COLLECTIONS:
    collection_name = coll['name']
    
    print(f"🔹 {collection_name}")
    print(f"   Kanal: {coll['channel']}")
    print(f"   Beschreibung: {coll['description']}")
    
    try:
        # Check if collection already has documents
        existing = db.collection(collection_name).limit(1).get()
        
        if len(existing) > 0:
            print(f"   ✅ Collection existiert bereits (überspringe Sample-Daten)")
        else:
            # Add sample document
            db.collection(collection_name).add(coll['sample_data'])
            print(f"   ✅ Sample-Dokument hinzugefügt")
    except Exception as e:
        print(f"   ❌ Fehler: {e}")
    
    print()

print("✅ Multi-Channel Collections Setup abgeschlossen!\n")

print("📋 NÄCHSTE SCHRITTE:")
print("   1. Firestore Security Rules aktualisieren (Firebase Console)")
print("   2. Composite Indexes erstellen (bei Bedarf)")
print("   3. Multi-Channel Daemon starten: php multi_channel_sync_madeline.php\n")

print("🔒 EMPFOHLENE SECURITY RULES (Development):")
print("""
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Alle Multi-Channel Collections
    match /{collection}/{document} {
      allow read: if true;
      allow write: if true;
    }
  }
}
""")
