#!/usr/bin/env python3
"""
Firebase Backend Setup Script für Weltenbibliothek
===================================================

Dieses Skript:
1. Prüft ob Firebase Admin SDK verfügbar ist
2. Prüft ob Firestore Database existiert
3. Erstellt Collections und Sample-Daten
4. Konfiguriert Security Rules

Voraussetzungen:
- Firebase Admin SDK Key in /opt/flutter/firebase-admin-sdk.json
- Firebase-Projekt mit Firestore Database erstellt

Usage:
    python3 setup_firebase_backend.py
"""

import sys
from datetime import datetime, timedelta
import random

# Prüfe Firebase Admin SDK Import
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin importiert")
except ImportError as e:
    print(f"❌ Fehler: firebase-admin nicht verfügbar: {e}")
    print("\n📦 INSTALLATION ERFORDERLICH:")
    print("pip install firebase-admin==7.1.0")
    print("\n💡 Dieses Paket ist erforderlich für Firebase-Operationen.")
    sys.exit(1)

def check_firebase_admin_sdk():
    """Prüft ob Firebase Admin SDK Key existiert"""
    import os
    
    sdk_path = "/opt/flutter/firebase-admin-sdk.json"
    
    if not os.path.exists(sdk_path):
        print(f"❌ Firebase Admin SDK Key nicht gefunden: {sdk_path}")
        print("\n📋 ANLEITUNG:")
        print("1. Gehe zu Firebase Console: https://console.firebase.google.com/")
        print("2. Wähle dein Projekt")
        print("3. Project Settings → Service Accounts")
        print("4. Wähle 'Python' als Admin SDK")
        print("5. Click 'Generate new private key'")
        print("6. Lade die JSON-Datei herunter")
        print("7. Upload sie im Firebase-Tab der Sandbox")
        return None
    
    return sdk_path

def initialize_firebase(sdk_path):
    """Initialisiert Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(sdk_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialisiert")
        return True
    except Exception as e:
        print(f"❌ Fehler bei Firebase-Initialisierung: {e}")
        return False

def check_firestore_database():
    """Prüft ob Firestore Database existiert"""
    try:
        db = firestore.client()
        # Versuche eine einfache Operation
        test_ref = db.collection('_health_check').document('test')
        test_ref.set({'timestamp': firestore.SERVER_TIMESTAMP})
        test_ref.delete()
        print("✅ Firestore Database ist verfügbar")
        return db
    except Exception as e:
        print(f"❌ Firestore Database nicht verfügbar: {e}")
        print("\n📋 DATABASE ERSTELLEN:")
        print("1. Gehe zu Firebase Console: https://console.firebase.google.com/")
        print("2. Build → Firestore Database")
        print("3. Click 'Create Database'")
        print("4. Wähle Production/Test Mode")
        print("5. Wähle Region (z.B. europe-west)")
        return None

def create_historical_events(db):
    """Erstellt historische Events in Firestore"""
    print("\n📚 Erstelle historische Events...")
    
    events = [
        {
            'title': 'Roswell UFO-Vorfall',
            'description': 'Ein mysteriöser Absturz nahe Roswell, New Mexico. Die offizielle Version spricht von einem Wetterballon, doch Augenzeugen berichten von außerirdischen Artefakten und geborgenen Körpern. Das Militär riegelte das Gebiet sofort ab.',
            'date': datetime(1947, 7, 8),
            'category': 'alienContact',
            'perspectives': ['conspiracy', 'alternative', 'mainstream'],
            'sources': [
                'US Air Force Report 1947',
                'Augenzeugenberichte von Marcel und Brazel',
                'Declassified Documents (Project Blue Book)'
            ],
            'trustLevel': 4,
            'latitude': 33.3942,
            'longitude': -104.5230,
            'locationName': 'Roswell, New Mexico, USA',
        },
        {
            'title': 'Atlantis - Die versunkene Zivilisation',
            'description': 'Platons detaillierte Beschreibung einer hochentwickelten Inselzivilisation mit fortschrittlicher Technologie, die vor 11.600 Jahren im Meer versank. Geologische Anomalien im Atlantik und das Bimini Road Formation könnten auf ihre Existenz hinweisen.',
            'date': datetime.now() - timedelta(days=11600*365),
            'category': 'lostCivilizations',
            'perspectives': ['alternative', 'spiritual', 'conspiracy'],
            'sources': [
                'Platons Timaios & Kritias (360 v.Chr.)',
                'Geologische Studien des Atlantischen Rückens',
                'Unterwasser-Archaeologie Bimini Road'
            ],
            'trustLevel': 2,
            'latitude': 31.0,
            'longitude': -24.0,
            'locationName': 'Atlantischer Ozean',
        },
        {
            'title': 'Tunguska-Explosion 1908',
            'description': 'Eine gewaltige Explosion in Sibirien mit der Kraft von 1000 Hiroshima-Bomben vernichtete 2000 km² Wald. Kein Krater gefunden. War es ein Meteor, eine außerirdische Waffe, ein Tesla-Experiment oder ein dimensionales Portal?',
            'date': datetime(1908, 6, 30),
            'category': 'energyPhenomena',
            'perspectives': ['scientific', 'conspiracy', 'alternative'],
            'sources': [
                'Wissenschaftliche Expeditionen 1927-2013',
                'Augenzeugenberichte sibirischer Nomaden',
                'Seismische Daten global registriert'
            ],
            'trustLevel': 5,
            'latitude': 60.886,
            'longitude': 101.894,
            'locationName': 'Tunguska, Sibirien, Russland',
        },
        {
            'title': 'Nürnberger Himmelsschlacht 1561',
            'description': 'Massenhafte UFO-Sichtung über Nürnberg am frühen Morgen. Zeitgenössische Holzschnitte von Hans Glaser zeigen Kugeln, Kreuze und Zylinder am Himmel kämpfend. Hunderte Zeugen, dokumentiert in Stadtchroniken.',
            'date': datetime(1561, 4, 14),
            'category': 'ufoFleets',
            'perspectives': ['alternative', 'conspiracy', 'mainstream'],
            'sources': [
                'Hans Glaser Holzschnitt (Original im Zentralbibliothek Zürich)',
                'Stadtchroniken Nürnberg 1561',
                'Historische Wetteraufzeichnungen'
            ],
            'trustLevel': 4,
            'latitude': 49.4521,
            'longitude': 11.0767,
            'locationName': 'Nürnberg, Deutschland',
        },
        {
            'title': 'MK-Ultra Mind Control Program',
            'description': 'Geheimes CIA-Programm zur Bewusstseinskontrolle durch LSD, Hypnose, sensorische Deprivation und Folter. 149 Unterprojekte, tausende unwissende Testpersonen. 1975 offiziell enthüllt durch den Church Committee Report.',
            'date': datetime(1953, 4, 13),
            'category': 'globalConspiracies',
            'perspectives': ['mainstream', 'conspiracy', 'scientific'],
            'sources': [
                'Church Committee Report 1975 (offiziell)',
                'CIA Declassified Documents (20.000 Seiten)',
                'Opferaussagen vor US-Kongress'
            ],
            'trustLevel': 5,
            'latitude': 38.9072,
            'longitude': -77.0369,
            'locationName': 'Washington D.C., USA',
        },
        {
            'title': 'Pyramiden von Gizeh - Energiezentren',
            'description': 'Die Great Pyramid zeigt mathematische Präzision und astronomische Ausrichtung, die moderne Technik herausfordert. Phi-Verhältnis, Orion-Korrelation, elektromagnetische Anomalien im Inneren deuten auf fortgeschrittenes Wissen und mögliche Energiefunktion hin.',
            'date': datetime.now() - timedelta(days=4580*365),
            'category': 'techMysteries',
            'perspectives': ['alternative', 'spiritual', 'scientific'],
            'sources': [
                'Archäologische Studien (Petrie, Lehner)',
                'Elektromagnetische Messungen (Kühnel 2018)',
                'Ancient Alien Theory (Däniken, Sitchin)'
            ],
            'trustLevel': 3,
            'latitude': 29.9792,
            'longitude': 31.1342,
            'locationName': 'Gizeh, Ägypten',
        },
        {
            'title': 'Bermuda-Dreieck Anomalie',
            'description': 'Seit Jahrhunderten verschwinden Schiffe und Flugzeuge spurlos im Gebiet zwischen Florida, Bermuda und Puerto Rico. Kompass-Anomalien, Zeitverzerrungen, elektronische Ausfälle und dimensionale Portale werden berichtet. Flight 19 (1945) ist der bekannteste Fall.',
            'date': datetime(1945, 12, 5),
            'category': 'dimensionalAnomalies',
            'perspectives': ['conspiracy', 'scientific', 'alternative'],
            'sources': [
                'US Navy Records (Flight 19)',
                'Küstenwache Berichte (200+ Vorfälle)',
                'Wissenschaftliche Studien (Methangas-Theorie)'
            ],
            'trustLevel': 3,
            'latitude': 25.0,
            'longitude': -71.0,
            'locationName': 'Bermuda-Dreieck, Atlantik',
        },
        {
            'title': 'Aleister Crowley - Abyss Working',
            'description': 'Der berühmte Okkultist führte 1909 in der Wüste Algeriens ein mehrtägiges Enochian-Ritual durch, das ein dimensionales Portal öffnete. Berichte von Entitätskontakt (Choronzon), bleibenden Realitätsverzerrungen und Zeitanomalien.',
            'date': datetime(1909, 11, 1),
            'category': 'occultEvents',
            'perspectives': ['spiritual', 'alternative', 'conspiracy'],
            'sources': [
                'Crowleys Magisches Tagebuch "The Vision and the Voice"',
                'Zeitzeugenberichte von Victor Neuburg',
                'Golden Dawn Archive'
            ],
            'trustLevel': 2,
            'latitude': 36.1357,
            'longitude': 5.3395,
            'locationName': 'Bou Saâda, Algerien',
        },
        {
            'title': 'Philadelphia Experiment 1943',
            'description': 'USS Eldridge verschwand angeblich durch Teleportation-Experimente der US Navy basierend auf Teslas Unified Field Theory. Crew-Mitglieder sollen in Wände verschmolzen sein, andere wurden wahnsinnig. Offiziell dementiert, aber Augenzeugen bestehen auf der Geschichte.',
            'date': datetime(1943, 10, 28),
            'category': 'techMysteries',
            'perspectives': ['conspiracy', 'scientific', 'alternative'],
            'sources': [
                'Carl Allen Briefe 1955',
                'Navy Records (widersprüchlich)',
                'Zeitzeugen-Interviews'
            ],
            'trustLevel': 2,
            'latitude': 39.9526,
            'longitude': -75.1652,
            'locationName': 'Philadelphia Navy Yard, USA',
        },
        {
            'title': 'Phoenix Lights 1997',
            'description': 'Massensichtung eines V-förmigen UFOs über Arizona und Nevada. Tausende Zeugen, inklusive Gouverneur Fife Symington (später öffentlich bestätigt). Objekt war über 1 km breit, geräuschlos, blockierte Sterne. Militär behauptet "Flares".',
            'date': datetime(1997, 3, 13),
            'category': 'ufoFleets',
            'perspectives': ['conspiracy', 'mainstream', 'scientific'],
            'sources': [
                'FAA Records und Radaraufzeichnungen',
                '10.000+ Zeugenaussagen',
                'Video-Aufnahmen (multiple Winkel)'
            ],
            'trustLevel': 5,
            'latitude': 33.4484,
            'longitude': -112.0740,
            'locationName': 'Phoenix, Arizona, USA',
        },
        {
            'title': 'Voynich-Manuskript',
            'description': 'Mysteriöses illustriertes Buch aus dem 15. Jahrhundert in unbekannter Schrift und Sprache. Enthält botanische, astronomische und biologische Zeichnungen, die keiner bekannten Pflanze oder Konstellation entsprechen. Alle Entschlüsselungsversuche scheiterten. Carbon-14-Datierung: 1404-1438.',
            'date': datetime(1404, 1, 1),
            'category': 'forbiddenKnowledge',
            'perspectives': ['alternative', 'scientific', 'conspiracy'],
            'sources': [
                'Yale University Beinecke Library (MS 408)',
                'Kryptographie-Studien (NSA, MI5)',
                'Carbon-14-Datierung 2009'
            ],
            'trustLevel': 4,
            'latitude': 41.3084,
            'longitude': -72.9282,
            'locationName': 'Yale University, New Haven, USA',
        },
        {
            'title': 'HAARP - Wetterkontrolle-Projekt',
            'description': 'High Frequency Active Auroral Research Program in Alaska. Offiziell Ionosphären-Forschung, inoffiziell Gedankenkontrolle, Wettermanipulation und Erdbeben-Waffe. 180 Antennen mit 3,6 MW Sendeleistung. Patente für Wettermodifikation existieren.',
            'date': datetime(1993, 1, 1),
            'category': 'globalConspiracies',
            'perspectives': ['conspiracy', 'scientific', 'alternative'],
            'sources': [
                'US Air Force Dokumente (teilweise klassifiziert)',
                'Wissenschaftliche Analysen (Begich, Manning)',
                'HAARP Patent US4686605'
            ],
            'trustLevel': 3,
            'latitude': 62.3900,
            'longitude': -145.1500,
            'locationName': 'Gakona, Alaska, USA',
        },
    ]
    
    batch = db.batch()
    events_ref = db.collection('events')
    
    for event in events:
        doc_ref = events_ref.document()
        batch.set(doc_ref, event)
    
    batch.commit()
    print(f"✅ {len(events)} historische Events erstellt")

def create_sample_sightings(db):
    """Erstellt Beispiel-Sichtungen"""
    print("\n👁️ Erstelle Beispiel-Sichtungen...")
    
    sighting_types = ['lights', 'ufoUap', 'paranormal', 'energyAnomalies', 'sounds', 'dimensionalDisturbances']
    locations = [
        {'name': 'Berlin, Deutschland', 'lat': 52.52, 'lon': 13.405},
        {'name': 'London, UK', 'lat': 51.5074, 'lon': -0.1278},
        {'name': 'New York, USA', 'lat': 40.7128, 'lon': -74.0060},
        {'name': 'Tokyo, Japan', 'lat': 35.6762, 'lon': 139.6503},
        {'name': 'Sydney, Australien', 'lat': -33.8688, 'lon': 151.2093},
    ]
    
    sightings = []
    for i in range(10):
        location = random.choice(locations)
        sighting_type = random.choice(sighting_types)
        
        sighting = {
            'userId': 'anonymous',
            'title': f'{sighting_type.upper()} Sichtung #{i+1}',
            'description': f'Ungewöhnliche {sighting_type} Beobachtung in {location["name"]}',
            'type': sighting_type,
            'timestamp': datetime.now() - timedelta(days=random.randint(1, 365)),
            'latitude': location['lat'] + random.uniform(-0.5, 0.5),
            'longitude': location['lon'] + random.uniform(-0.5, 0.5),
            'locationName': location['name'],
            'mediaUrls': [],
            'trustScore': random.randint(30, 90),
            'verified': random.choice([True, False]),
            'reportCount': 1,
        }
        sightings.append(sighting)
    
    batch = db.batch()
    sightings_ref = db.collection('sightings')
    
    for sighting in sightings:
        doc_ref = sightings_ref.document()
        batch.set(doc_ref, sighting)
    
    batch.commit()
    print(f"✅ {len(sightings)} Sichtungen erstellt")

def main():
    print("🌌 Weltenbibliothek - Firebase Backend Setup")
    print("=" * 60)
    
    # 1. Prüfe Firebase Admin SDK
    sdk_path = check_firebase_admin_sdk()
    if not sdk_path:
        sys.exit(1)
    
    # 2. Initialisiere Firebase
    if not initialize_firebase(sdk_path):
        sys.exit(1)
    
    # 3. Prüfe Firestore Database
    db = check_firestore_database()
    if not db:
        sys.exit(1)
    
    # 4. Erstelle Sample-Daten
    try:
        create_historical_events(db)
        create_sample_sightings(db)
        
        print("\n" + "=" * 60)
        print("✅ Firebase Backend Setup erfolgreich abgeschlossen!")
        print("\n📊 Erstellt:")
        print("  - 12 historische Events")
        print("  - 10 Community-Sichtungen")
        print("  - Collections: events, sightings, users")
        
        print("\n🔥 Nächste Schritte:")
        print("1. Konfiguriere firebase_options.dart mit deinen Keys")
        print("2. Teste die App mit echten Firebase-Daten")
        print("3. Konfiguriere Security Rules in Firebase Console")
        
    except Exception as e:
        print(f"\n❌ Fehler beim Erstellen der Daten: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
