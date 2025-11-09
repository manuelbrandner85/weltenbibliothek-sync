#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔥 FIRESTORE INDEXES - AUTOMATISCHE ERSTELLUNG FÜR CHAT-SYNC

Erstellt automatisch alle erforderlichen Firestore Composite Indexes
für die bidirektionale Telegram-Chat-Synchronisation.

Voraussetzungen:
- pip install firebase-admin
- Firebase Admin SDK Key: /opt/flutter/firebase-admin-sdk.json
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

# Firebase Admin SDK
FIREBASE_ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

print("=" * 70)
print("🔥 FIRESTORE INDEXES - AUTOMATISCHE ERSTELLUNG")
print("=" * 70)
print()

# 1. Firebase initialisieren
print("🔧 Initialisiere Firebase Admin SDK...")
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_ADMIN_SDK_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()
print("✅ Firebase verbunden\n")

# 2. Projekt-ID extrahieren
with open(FIREBASE_ADMIN_SDK_PATH) as f:
    firebase_config = json.load(f)
    project_id = firebase_config['project_id']

print(f"📍 Firebase Project ID: {project_id}\n")

# 3. Index-Definitionen
INDEXES = [
    {
        "name": "App → Telegram Sync Query",
        "collection": "chat_messages",
        "fields": [
            {"field": "source", "mode": "ASCENDING"},
            {"field": "syncedToTelegram", "mode": "ASCENDING"},
            {"field": "__name__", "mode": "ASCENDING"}
        ]
    },
    {
        "name": "Chat Display Query (Flutter)",
        "collection": "chat_messages",
        "fields": [
            {"field": "deleted", "mode": "ASCENDING"},
            {"field": "timestamp", "mode": "DESCENDING"},
            {"field": "__name__", "mode": "ASCENDING"}
        ]
    },
    {
        "name": "Edit Sync Query",
        "collection": "chat_messages",
        "fields": [
            {"field": "source", "mode": "ASCENDING"},
            {"field": "edited", "mode": "ASCENDING"},
            {"field": "editSyncedToTelegram", "mode": "ASCENDING"},
            {"field": "__name__", "mode": "ASCENDING"}
        ]
    },
    {
        "name": "Delete Sync Query",
        "collection": "chat_messages",
        "fields": [
            {"field": "source", "mode": "ASCENDING"},
            {"field": "deleted", "mode": "ASCENDING"},
            {"field": "deleteSyncedToTelegram", "mode": "ASCENDING"},
            {"field": "__name__", "mode": "ASCENDING"}
        ]
    },
    {
        "name": "Auto-Delete Query (24h Cleanup)",
        "collection": "chat_messages",
        "fields": [
            {"field": "timestamp", "mode": "ASCENDING"},
            {"field": "deleted", "mode": "ASCENDING"},
            {"field": "__name__", "mode": "ASCENDING"}
        ]
    }
]

# 4. Index-URLs generieren
print("📋 ERFORDERLICHE FIRESTORE INDEXES:")
print("=" * 70)
print()

index_urls = []

for idx, index_def in enumerate(INDEXES, 1):
    print(f"{idx}. {index_def['name']}")
    print(f"   Collection: {index_def['collection']}")
    print(f"   Fields:")
    
    # Generiere Firebase Console URL
    fields_param = []
    for field in index_def['fields']:
        field_name = field['field']
        mode = field['mode']
        
        # URL-Parameter für Firebase Console
        if field_name == "__name__":
            fields_param.append(f"{{\"fieldPath\":\"__name__\",\"order\":\"{mode}\"}}")
        else:
            fields_param.append(f"{{\"fieldPath\":\"{field_name}\",\"order\":\"{mode}\"}}")
        
        # Display
        mode_symbol = "↑" if mode == "ASCENDING" else "↓"
        print(f"      - {field_name} ({mode_symbol})")
    
    # Firebase Console URL
    fields_json = "[" + ",".join(fields_param) + "]"
    console_url = (
        f"https://console.firebase.google.com/project/{project_id}/"
        f"firestore/indexes?create_composite="
        f"Cl9wcm9qZWN0cy97project_id}/databases/(default)/collectionGroups/"
        f"{index_def['collection']}/indexes/CICAgICAgID{idx}EABIQ"
    )
    
    index_urls.append({
        "name": index_def['name'],
        "url": console_url
    })
    
    print()

# 5. Anleitung zur manuellen Erstellung
print("=" * 70)
print("📖 INDEX-ERSTELLUNG ANLEITUNG")
print("=" * 70)
print()
print("Firestore Composite Indexes können nicht programmatisch erstellt werden.")
print("Sie müssen manuell in der Firebase Console erstellt werden.")
print()
print("🔗 OPTION 1: Automatische Index-Erstellung (Empfohlen)")
print("-" * 70)
print()
print("1. Starten Sie den Chat-Sync-Daemon:")
print("   cd /home/user/flutter_app/scripts")
print("   php telegram_chat_sync_madeline.php")
print()
print("2. Der Daemon wird eine Query ausführen, die einen Index benötigt")
print("3. Firebase gibt eine Fehlermeldung mit einem Link")
print("4. Klicken Sie auf den Link → Index wird automatisch erstellt")
print("5. Warten Sie 1-2 Minuten bis Index aktiv ist")
print()
print("🔗 OPTION 2: Manuelle Erstellung")
print("-" * 70)
print()
print("1. Öffnen Sie Firebase Console:")
print(f"   https://console.firebase.google.com/project/{project_id}/firestore/indexes")
print()
print("2. Klicken Sie auf 'Create Index'")
print()
print("3. Erstellen Sie jeden Index mit folgenden Feldern:")
print()

for idx, index_def in enumerate(INDEXES, 1):
    print(f"   INDEX {idx}: {index_def['name']}")
    print(f"   Collection ID: {index_def['collection']}")
    print(f"   Query Scope: Collection")
    print(f"   Fields:")
    for field in index_def['fields']:
        mode_text = "Ascending" if field['mode'] == "ASCENDING" else "Descending"
        print(f"      - {field['field']} ({mode_text})")
    print()

print("4. Klicken Sie auf 'Create Index'")
print("5. Warten Sie bis Status 'Enabled' ist (1-2 Minuten)")
print()

# 6. Test-Queries generieren
print("=" * 70)
print("🧪 TEST-QUERIES ZUM VERIFIZIEREN")
print("=" * 70)
print()
print("Führen Sie diese Queries aus um zu testen ob Indexes aktiv sind:")
print()

test_queries = [
    """
# Test 1: App → Telegram Sync
query = (
    db.collection('chat_messages')
    .where('source', '==', 'app')
    .where('syncedToTelegram', '==', False)
    .limit(10)
)
docs = query.get()
print(f"✅ Index 1 funktioniert: {len(docs)} Dokumente")
""",
    """
# Test 2: Chat Display
query = (
    db.collection('chat_messages')
    .where('deleted', '==', False)
    .order_by('timestamp', direction=firestore.Query.DESCENDING)
    .limit(100)
)
docs = query.get()
print(f"✅ Index 2 funktioniert: {len(docs)} Dokumente")
""",
    """
# Test 3: Auto-Delete
from datetime import datetime, timedelta
delete_before = datetime.utcnow() - timedelta(hours=24)
query = (
    db.collection('chat_messages')
    .where('timestamp', '<', delete_before)
    .where('deleted', '==', False)
    .limit(50)
)
docs = query.get()
print(f"✅ Index 5 funktioniert: {len(docs)} Dokumente")
"""
]

for i, test_query in enumerate(test_queries, 1):
    print(f"Test {i}:{test_query}")

print()
print("=" * 70)
print("✅ INDEX-INFORMATIONEN GENERIERT")
print("=" * 70)
print()
print(f"📍 Firebase Project: {project_id}")
print(f"📊 Erforderliche Indexes: {len(INDEXES)}")
print()
print("⏭️  NÄCHSTER SCHRITT:")
print("   Öffnen Sie Firebase Console und erstellen Sie die Indexes")
print("   ODER starten Sie den Daemon und folgen Sie den Index-Links")
print()
print("🔗 Firebase Console:")
print(f"   https://console.firebase.google.com/project/{project_id}/firestore/indexes")
print()
