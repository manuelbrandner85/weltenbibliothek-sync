#!/usr/bin/env python3
"""
Fix Firebase Storage photoURL Errors
Setzt fehlerhafte/ungültige photoURL-Werte auf leer
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys

def fix_photo_urls():
    """Bereinige fehlerhafte photoURL-Einträge"""
    try:
        # Initialize Firebase Admin SDK
        cred = credentials.Certificate('/opt/flutter/firebase-admin-sdk.json')
        firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        
        print("🔍 Suche Users mit fehlerhaften photoURL...")
        
        # Hole alle Users
        users_ref = db.collection('users')
        users = users_ref.get()
        
        fixed_count = 0
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            photo_url = user_data.get('photoURL', '')
            
            # Prüfe ob photoURL ungültig ist
            if photo_url and not photo_url.startswith('http'):
                print(f"  ⚠️  Bereinige User: {user_data.get('displayName', 'Unknown')}")
                print(f"      Alte photoURL: {photo_url}")
                
                # Setze photoURL auf leer
                users_ref.document(user_doc.id).update({
                    'photoURL': ''
                })
                
                fixed_count += 1
        
        if fixed_count > 0:
            print(f"\n✅ {fixed_count} User-Profile bereinigt")
        else:
            print("\n✅ Keine fehlerhaften photoURLs gefunden")
        
        return True
        
    except Exception as e:
        print(f"❌ Fehler: {e}")
        return False

if __name__ == '__main__':
    success = fix_photo_urls()
    sys.exit(0 if success else 1)
