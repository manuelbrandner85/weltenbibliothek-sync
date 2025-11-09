#!/usr/bin/env python3
"""Firestore Indexes Info für Chat-Sync"""
import firebase_admin
from firebase_admin import credentials
import json

# Firebase Admin SDK
SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

print("=" * 70)
print("🔥 FIRESTORE INDEXES FÜR CHAT-SYNC")
print("=" * 70)
print()

# Projekt-ID laden
with open(SDK_PATH) as f:
    project_id = json.load(f)['project_id']

print(f"📍 Firebase Project: {project_id}")
print()
print("🔗 Firebase Console:")
print(f"   https://console.firebase.google.com/project/{project_id}/firestore/indexes")
print()
print("=" * 70)
print("📋 ERFORDERLICHE INDEXES (5 Stück)")
print("=" * 70)
print()

indexes = [
    ("App → Telegram Sync", [
        ("source", "↑"), ("syncedToTelegram", "↑"), ("__name__", "↑")
    ]),
    ("Chat Display (Flutter)", [
        ("deleted", "↑"), ("timestamp", "↓"), ("__name__", "↑")
    ]),
    ("Edit Sync", [
        ("source", "↑"), ("edited", "↑"), ("editSyncedToTelegram", "↑"), ("__name__", "↑")
    ]),
    ("Delete Sync", [
        ("source", "↑"), ("deleted", "↑"), ("deleteSyncedToTelegram", "↑"), ("__name__", "↑")
    ]),
    ("Auto-Delete (24h)", [
        ("timestamp", "↑"), ("deleted", "↑"), ("__name__", "↑")
    ])
]

for i, (name, fields) in enumerate(indexes, 1):
    print(f"{i}. {name}")
    print(f"   Collection: chat_messages")
    print(f"   Fields:")
    for field, direction in fields:
        mode = "Ascending" if direction == "↑" else "Descending"
        print(f"      - {field} ({direction} {mode})")
    print()

print("=" * 70)
print("📖 ERSTELLUNG")
print("=" * 70)
print()
print("✅ EINFACHSTE METHODE:")
print("   1. Starte Chat-Sync-Daemon")
print("   2. Daemon macht Query → Fehler mit Index-Link")
print("   3. Klicke auf Link → Index wird erstellt")
print("   4. Warte 1-2 Minuten")
print()
print("📝 MANUELLE METHODE:")
print("   1. Öffne Firebase Console (Link oben)")
print("   2. Klicke 'Create Index'")
print("   3. Trage Felder ein (siehe Liste oben)")
print("   4. Klicke 'Create'")
print()
