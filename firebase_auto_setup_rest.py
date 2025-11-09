#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
🔥 FIREBASE INDEX AUTO-SETUP - MIT GOOGLE CLOUD REST API
═══════════════════════════════════════════════════════════════
Erstellt alle Firestore Indexes automatisch über REST API
═══════════════════════════════════════════════════════════════
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import requests
from google.auth.transport.requests import Request

PROJECT_ID = "weltenbibliothek-5d21f"
ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

print("\n🔥 FIREBASE INDEX AUTO-CREATOR MIT REST API\n")

# Initialisiere Firebase Admin SDK
cred = credentials.Certificate(ADMIN_SDK_PATH)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)

# Hole Access Token
access_token = cred.get_access_token().access_token

print(f"✅ Access Token erhalten")
print(f"📊 Erstelle 9 Composite Indexes...\n")

# Firestore Admin API Endpoint
FIRESTORE_API = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/collectionGroups"

# Index Definitionen
indexes = [
    # EVENTS - Index 1
    {
        "collectionGroup": "events",
        "fields": [
            {"fieldPath": "category", "order": "ASCENDING"},
            {"fieldPath": "date", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # EVENTS - Index 2
    {
        "collectionGroup": "events",
        "fields": [
            {"fieldPath": "category", "order": "ASCENDING"},
            {"fieldPath": "title", "order": "ASCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # EVENTS - Index 3
    {
        "collectionGroup": "events",
        "fields": [
            {"fieldPath": "featured", "order": "DESCENDING"},
            {"fieldPath": "date", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # EVENTS - Index 4
    {
        "collectionGroup": "events",
        "fields": [
            {"fieldPath": "category", "order": "ASCENDING"},
            {"fieldPath": "featured", "order": "DESCENDING"},
            {"fieldPath": "date", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # TELEGRAM_MEDIA - Index 5
    {
        "collectionGroup": "telegram_media",
        "fields": [
            {"fieldPath": "category", "order": "ASCENDING"},
            {"fieldPath": "timestamp", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # TELEGRAM_MEDIA - Index 6
    {
        "collectionGroup": "telegram_media",
        "fields": [
            {"fieldPath": "media_type", "order": "ASCENDING"},
            {"fieldPath": "timestamp", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # TELEGRAM_MEDIA - Index 7
    {
        "collectionGroup": "telegram_media",
        "fields": [
            {"fieldPath": "category", "order": "ASCENDING"},
            {"fieldPath": "media_type", "order": "ASCENDING"},
            {"fieldPath": "timestamp", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # CATEGORIES - Index 8
    {
        "collectionGroup": "categories",
        "fields": [
            {"fieldPath": "event_count", "order": "DESCENDING"},
            {"fieldPath": "name", "order": "ASCENDING"}
        ],
        "queryScope": "COLLECTION"
    },
    # CATEGORIES - Index 9
    {
        "collectionGroup": "categories",
        "fields": [
            {"fieldPath": "name", "order": "ASCENDING"},
            {"fieldPath": "event_count", "order": "DESCENDING"}
        ],
        "queryScope": "COLLECTION"
    }
]

# Erstelle jeden Index
created_count = 0
failed_count = 0

for i, index_def in enumerate(indexes, 1):
    collection_group = index_def["collectionGroup"]
    
    # API Endpoint für diese Collection Group
    url = f"{FIRESTORE_API}/{collection_group}/indexes"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
    # Entferne collectionGroup aus dem Body (wird in URL verwendet)
    body = {
        "fields": index_def["fields"],
        "queryScope": index_def["queryScope"]
    }
    
    try:
        response = requests.post(url, headers=headers, json=body)
        
        if response.status_code in [200, 201]:
            print(f"✅ Index {i}/9 erstellt: {collection_group}")
            created_count += 1
        elif response.status_code == 409:
            print(f"⚠️  Index {i}/9 existiert bereits: {collection_group}")
            created_count += 1
        else:
            print(f"❌ Index {i}/9 fehlgeschlagen: {collection_group}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            failed_count += 1
            
    except Exception as e:
        print(f"❌ Index {i}/9 Exception: {collection_group}")
        print(f"   {str(e)}")
        failed_count += 1

print("\n" + "═" * 63)
print("📊 INDEX ERSTELLUNG ABGESCHLOSSEN")
print("═" * 63)
print(f"✅ Erfolgreich: {created_count}/9")
print(f"❌ Fehlgeschlagen: {failed_count}/9")
print()

if created_count == 9:
    print("🎉 ALLE INDEXES ERFOLGREICH ERSTELLT!")
    print()
    print("⏳ Index-Build läuft im Hintergrund (5-15 Minuten)")
    print(f"   Status prüfen: https://console.firebase.google.com/project/{PROJECT_ID}/firestore/indexes")
elif created_count > 0:
    print("⚠️  TEILWEISE ERFOLGREICH")
    print()
    print("💡 Fehlende Indexes können über die Setup-Seite erstellt werden:")
    print("   https://5060-i0sts42562ps3y0etjezb-cc2fbc16.sandbox.novita.ai/firebase-setup.html")
else:
    print("❌ KEINE INDEXES ERSTELLT")
    print()
    print("📋 MANUELLE ALTERNATIVE:")
    print("   1. Öffne: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes")
    print("   2. Nutze die One-Click Setup Seite:")
    print("      https://5060-i0sts42562ps3y0etjezb-cc2fbc16.sandbox.novita.ai/firebase-setup.html")

print("\n" + "═" * 63)

