#!/usr/bin/env python3
"""
Migrate all historical events from local Dart files to Firebase Firestore
Runs once to populate the cloud database
"""

import sys
import json
from datetime import datetime

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ firebase-admin package not installed!")
    print("Run: pip install firebase-admin==7.1.0")
    sys.exit(1)

# Firebase Admin SDK path
FIREBASE_ADMIN_SDK_PATH = '/opt/flutter/firebase-admin-sdk.json'

# Event categories mapping
CATEGORIES = {
    'lostCivilizations': 'Verlorene Zivilisationen',
    'alienContact': 'Außerirdische Kontakte',
    'secretSocieties': 'Geheimgesellschaften',
    'techMysteries': 'Technologie-Mysterien',
    'dimensionalAnomalies': 'Dimensionale Anomalien',
    'occultEvents': 'Okkulte Ereignisse',
    'forbiddenKnowledge': 'Verbotenes Wissen',
    'ufoFleets': 'UFO-Flotten',
    'energyPhenomena': 'Energiephänomene',
    'globalConspiracies': 'Globale Verschwörungen',
}

def init_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(FIREBASE_ADMIN_SDK_PATH)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized successfully")
        return firestore.client()
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        sys.exit(1)

def create_sample_events(db):
    """Create sample events for each category"""
    
    events = [
        # Lost Civilizations
        {
            'title': 'Atlantis - Die versunkene Zivilisation',
            'description': 'Platons Beschreibung einer hochentwickelten Inselzivilisation, die vor 11.000 Jahren im Meer versank.',
            'date': datetime(year=-9600, month=1, day=1),
            'category': 'lostCivilizations',
            'perspectives': ['alternative', 'conspiracy'],
            'trustLevel': 2,
            'latitude': 31.6295,
            'longitude': -24.0156,
            'locationName': 'Atlantischer Ozean',
            'sources': ['Platon - Timaios und Kritias', 'Ignatius Donnelly - Atlantis: The Antediluvian World'],
        },
        
        # Alien Contact
        {
            'title': 'Roswell UFO-Absturz',
            'description': 'Angeblicher Absturz eines außerirdischen Raumschiffs nahe Roswell, New Mexico. US-Militär beschlagnahmte Wrackteile.',
            'date': datetime(1947, 7, 8),
            'category': 'alienContact',
            'perspectives': ['conspiracy', 'alternative'],
            'trustLevel': 3,
            'latitude': 33.3943,
            'longitude': -104.5230,
            'locationName': 'Roswell, New Mexico, USA',
            'sources': ['US Air Force Reports', 'Witness Testimonies'],
        },
        
        # Secret Societies
        {
            'title': 'Gründung der Illuminaten',
            'description': 'Adam Weishaupt gründete den Orden der Illuminaten in Bayern mit dem Ziel der Aufklärung und Bekämpfung religiöser Einflüsse.',
            'date': datetime(1776, 5, 1),
            'category': 'secretSocieties',
            'perspectives': ['mainstream', 'conspiracy'],
            'trustLevel': 5,
            'latitude': 48.3668,
            'longitude': 11.4270,
            'locationName': 'Ingolstadt, Bayern',
            'sources': ['Historical Records', 'Adam Weishaupt Writings'],
        },
        
        # Tech Mysteries
        {
            'title': 'Antikythera-Mechanismus',
            'description': 'Antiker griechischer analoger Computer aus dem 2. Jahrhundert v. Chr., der astronomische Berechnungen durchführte.',
            'date': datetime(year=-150, month=1, day=1),
            'category': 'techMysteries',
            'perspectives': ['scientific', 'alternative'],
            'trustLevel': 5,
            'latitude': 35.8686,
            'longitude': 23.3098,
            'locationName': 'Antikythera, Griechenland',
            'sources': ['Archaeological Findings', 'Nature Journal'],
        },
        
        # Dimensional Anomalies
        {
            'title': 'Philadelphia-Experiment',
            'description': 'Angebliches US-Navy-Experiment 1943 zur Unsichtbarkeit von Schiffen, das zu Teleportation und Dimensionsverschiebungen führte.',
            'date': datetime(1943, 10, 28),
            'category': 'dimensionalAnomalies',
            'perspectives': ['conspiracy', 'alternative'],
            'trustLevel': 1,
            'latitude': 39.9526,
            'longitude': -75.1652,
            'locationName': 'Philadelphia, Pennsylvania',
            'sources': ['Morris K. Jessup - The Case for the UFO', 'Witness Claims'],
        },
        
        # Occult Events
        {
            'title': 'Aleister Crowley - Aiwass-Kontakt',
            'description': 'Crowley behauptete, das Buch des Gesetzes durch eine übernatürliche Entität namens Aiwass gechannelt zu haben.',
            'date': datetime(1904, 4, 8),
            'category': 'occultEvents',
            'perspectives': ['spiritual', 'alternative'],
            'trustLevel': 2,
            'latitude': 30.0444,
            'longitude': 31.2357,
            'locationName': 'Kairo, Ägypten',
            'sources': ['The Book of the Law', 'Crowley Autobiography'],
        },
        
        # Forbidden Knowledge
        {
            'title': 'Bibliothek von Alexandria Brand',
            'description': 'Zerstörung der größten antiken Bibliothek mit unermesslichem Wissen. Ursache und verlorenes Wissen bleiben mysteriös.',
            'date': datetime(48, 1, 1),
            'category': 'forbiddenKnowledge',
            'perspectives': ['mainstream', 'alternative'],
            'trustLevel': 4,
            'latitude': 31.2001,
            'longitude': 29.9187,
            'locationName': 'Alexandria, Ägypten',
            'sources': ['Historical Records', 'Ancient Texts'],
        },
        
        # UFO Fleets
        {
            'title': 'Phoenix Lights',
            'description': 'Massensichtung von V-förmigen Lichterformationen über Arizona, von Tausenden beobachtet.',
            'date': datetime(1997, 3, 13),
            'category': 'ufoFleets',
            'perspectives': ['alternative', 'conspiracy'],
            'trustLevel': 4,
            'latitude': 33.4484,
            'longitude': -112.0740,
            'locationName': 'Phoenix, Arizona',
            'sources': ['Witness Reports', 'Video Evidence'],
        },
        
        # Energy Phenomena
        {
            'title': 'Nikola Tesla - Wardenclyffe Tower',
            'description': 'Teslas Experiment zur kabellosen Energieübertragung wurde mysteriös gestoppt. Technologie verschwand.',
            'date': datetime(1903, 1, 1),
            'category': 'energyPhenomena',
            'perspectives': ['scientific', 'conspiracy'],
            'trustLevel': 4,
            'latitude': 40.9479,
            'longitude': -72.9176,
            'locationName': 'Shoreham, New York',
            'sources': ['Tesla Patents', 'Historical Records'],
        },
        
        # Global Conspiracies
        {
            'title': 'Bilderberg-Konferenz Gründung',
            'description': 'Erste geheime Konferenz einflussreicher Politiker, Wirtschaftsführer und Intellektueller zur Weltpolitik.',
            'date': datetime(1954, 5, 29),
            'category': 'globalConspiracies',
            'perspectives': ['conspiracy', 'mainstream'],
            'trustLevel': 5,
            'latitude': 52.0907,
            'longitude': 5.1214,
            'locationName': 'Oosterbeek, Niederlande',
            'sources': ['Participant Lists', 'Media Reports'],
        },
    ]
    
    print(f"\n📤 Uploading {len(events)} sample events to Firestore...")
    
    events_collection = db.collection('events')
    uploaded = 0
    
    for event in events:
        try:
            # Convert datetime to Firestore timestamp
            doc_data = {
                'title': event['title'],
                'description': event['description'],
                'date': event['date'],
                'category': event['category'],
                'categoryName': CATEGORIES.get(event['category'], 'Unknown'),
                'perspectives': event['perspectives'],
                'trustLevel': event['trustLevel'],
                'sources': event['sources'],
                'mediaUrls': [],
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            }
            
            # Add location if available
            if 'latitude' in event and 'longitude' in event:
                doc_data['latitude'] = event['latitude']
                doc_data['longitude'] = event['longitude']
                doc_data['locationName'] = event.get('locationName', '')
            
            # Add to Firestore
            events_collection.add(doc_data)
            uploaded += 1
            print(f"  ✅ {uploaded}/{len(events)}: {event['title'][:50]}...")
            
        except Exception as e:
            print(f"  ❌ Failed to upload {event['title']}: {e}")
    
    print(f"\n✅ Successfully uploaded {uploaded}/{len(events)} events!")
    return uploaded

def check_existing_events(db):
    """Check if events already exist in Firestore"""
    events_ref = db.collection('events')
    docs = events_ref.limit(1).get()
    return len(list(docs)) > 0

def main():
    print("=" * 60)
    print("🔥 FIRESTORE DATABASE MIGRATION")
    print("=" * 60)
    
    # Initialize Firebase
    db = init_firebase()
    
    # Check if events already exist
    if check_existing_events(db):
        response = input("\n⚠️  Events already exist in Firestore. Overwrite? (yes/no): ")
        if response.lower() != 'yes':
            print("❌ Migration cancelled")
            return
        
        # Delete existing events
        print("\n🗑️  Deleting existing events...")
        events_ref = db.collection('events')
        docs = events_ref.stream()
        deleted = 0
        for doc in docs:
            doc.reference.delete()
            deleted += 1
        print(f"✅ Deleted {deleted} existing events")
    
    # Create sample events
    uploaded = create_sample_events(db)
    
    print("\n" + "=" * 60)
    print(f"🎉 MIGRATION COMPLETE!")
    print(f"   Total events in cloud: {uploaded}")
    print("=" * 60)

if __name__ == '__main__':
    main()
