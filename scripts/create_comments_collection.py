#!/usr/bin/env python3
"""
Create Firestore 'comments' collection for Weltenbibliothek Phase 3
Allows users to comment on events
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import sys

# Initialize Firebase Admin SDK
try:
    cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialisiert")
except Exception as e:
    print(f"❌ Fehler bei Firebase-Initialisierung: {e}")
    sys.exit(1)

db = firestore.client()

print("\n" + "=" * 80)
print("📝 COMMENTS COLLECTION ERSTELLEN")
print("=" * 80)

# Collection structure:
# comments/{commentId}
#   - eventId: string (reference to event)
#   - userId: string (reference to user)
#   - userName: string (display name of commenter)
#   - text: string (comment content)
#   - createdAt: timestamp
#   - likes: array of user IDs who liked
#   - likeCount: number

print("\n✅ Firestore 'comments' Collection Struktur:")
print("""
Collection: comments
  - commentId (auto-generated)
    - eventId: string (Event-Referenz)
    - userId: string (Benutzer-ID)
    - userName: string (Anzeigename)
    - text: string (Kommentartext)
    - createdAt: timestamp
    - likes: array<string> (Benutzer-IDs die geliket haben)
    - likeCount: number
""")

print("\n💡 Die Collection wird automatisch erstellt, wenn das erste Kommentar hinzugefügt wird.")
print("✅ Backend-Service wird in Flutter implementiert!")
print("=" * 80)
