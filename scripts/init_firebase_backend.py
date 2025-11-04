#!/usr/bin/env python3
"""
Firebase Backend Initialisierung für Weltenbibliothek
Erstellt Firestore-Collections mit Sample-Daten für alle 10 Event-Kategorien
"""

import sys
from datetime import datetime, timedelta
import random

# Firebase Admin SDK Check
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    sys.exit(1)

# Firebase Admin SDK Key Path
FIREBASE_KEY_PATH = "/opt/flutter/firebase-admin-sdk.json"

def init_firebase():
    """Initialisiere Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(FIREBASE_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase Admin SDK initialisiert")
        return firestore.client()
    except Exception as e:
        print(f"❌ Firebase Initialisierung fehlgeschlagen: {e}")
        print(f"\n📝 Stelle sicher, dass {FIREBASE_KEY_PATH} existiert")
        sys.exit(1)

def create_sample_events(db):
    """Erstelle Sample Events für alle 10 Kategorien"""
    
    events = [
        # 1. Lost Civilizations (Verlorene Zivilisationen)
        {
            'title': 'Atlantis - Die versunkene Zivilisation',
            'description': 'Platons Beschreibung einer hochentwickelten Inselzivilisation, die vor 11.600 Jahren im Meer versank. Geologische Studien suchen nach Beweisen.',
            'date': datetime(1, 1, 1) - timedelta(days=365*9600),  # 9600 v.Chr.
            'category': 'lostCivilizations',
            'perspectives': ['alternative', 'spiritual', 'mainstream'],
            'sources': ['Platons Timaios & Kritias', 'Geologische Studien', 'Antike Texte'],
            'trustLevel': 2,
            'latitude': 31.0,
            'longitude': -24.0,
            'locationName': 'Atlantischer Ozean',
            'tags': ['atlantis', 'platon', 'versunkene_stadt'],
        },
        {
            'title': 'Pyramiden von Gizeh - Baumeister-Geheimnis',
            'description': 'Monumentale Bauwerke mit präziser astronomischer Ausrichtung. Die Bauweise mit 2,3-Millionen-Tonnen-Steinen ist bis heute rätselhaft.',
            'date': datetime(1, 1, 1) - timedelta(days=365*2580),  # 2580 v.Chr.
            'category': 'lostCivilizations',
            'perspectives': ['mainstream', 'alternative', 'scientific'],
            'sources': ['Archäologische Forschung', 'Herodots Historien', 'Astronomische Studien'],
            'trustLevel': 5,
            'latitude': 29.9792,
            'longitude': 31.1342,
            'locationName': 'Gizeh, Ägypten',
            'tags': ['pyramiden', 'ägypten', 'antike_technologie'],
        },
        
        # 2. Alien Contact (Außerirdische Kontakte)
        {
            'title': 'Roswell UFO-Absturz',
            'description': 'Ein mysteriöser Absturz nahe Roswell, New Mexico im Juli 1947. Offiziell ein Wetterballon, doch Augenzeugen berichten von außerirdischen Artefakten und Leichnamen.',
            'date': datetime(1947, 7, 8),
            'category': 'alienContact',
            'perspectives': ['conspiracy', 'alternative', 'mainstream'],
            'sources': ['US Air Force Report 1947', 'Augenzeugenberichte', 'Declassified Documents'],
            'trustLevel': 4,
            'latitude': 33.3942,
            'longitude': -104.5230,
            'locationName': 'Roswell, New Mexico, USA',
            'tags': ['roswell', 'ufo', 'area_51', 'grey_aliens'],
        },
        {
            'title': 'Rendlesham Forest Incident',
            'description': 'UFO-Landung nahe RAF-Basis in England 1980. Militärzeugen beobachteten leuchtende Objekte über mehrere Nächte. Offizielles Logbuch existiert.',
            'date': datetime(1980, 12, 26),
            'category': 'alienContact',
            'perspectives': ['conspiracy', 'mainstream', 'alternative'],
            'sources': ['RAF Reports', 'Lt. Col. Charles Halt Memo', 'Military Witnesses'],
            'trustLevel': 4,
            'latitude': 52.0943,
            'longitude': 1.4474,
            'locationName': 'Rendlesham Forest, Suffolk, England',
            'tags': ['rendlesham', 'ufo_landing', 'military'],
        },
        
        # 3. Secret Societies (Geheimgesellschaften)
        {
            'title': 'MK-Ultra Mind Control Programm',
            'description': 'CIA-Programm zur Bewusstseinskontrolle durch LSD, Folter und Hypnose (1953-1973). Offiziell bestätigt durch freigegebene Dokumente 1977.',
            'date': datetime(1953, 4, 13),
            'category': 'secretSocieties',
            'perspectives': ['mainstream', 'conspiracy', 'scientific'],
            'sources': ['CIA Declassified Documents', 'Congressional Hearings 1977', 'FOIA Files'],
            'trustLevel': 5,
            'latitude': 38.9072,
            'longitude': -77.0369,
            'locationName': 'Washington D.C., USA',
            'tags': ['mkultra', 'cia', 'mind_control'],
        },
        {
            'title': 'Bohemian Grove Rituale',
            'description': 'Jährliches Treffen der Elite im kalifornischen Redwood-Wald. "Cremation of Care"-Zeremonie vor 40-Fuß-Eule. Mitglieder: US-Präsidenten, CEOs.',
            'date': datetime(1872, 1, 1),
            'category': 'secretSocieties',
            'perspectives': ['conspiracy', 'alternative', 'mainstream'],
            'sources': ['Member Lists', 'Leaked Videos', 'Investigative Journalism'],
            'trustLevel': 4,
            'latitude': 38.4108,
            'longitude': -123.0122,
            'locationName': 'Monte Rio, California, USA',
            'tags': ['bohemian_grove', 'elite', 'rituale'],
        },
        
        # 4. Tech Mysteries (Technologie-Mysterien)
        {
            'title': 'Antikythera-Mechanismus - Antiker Computer',
            'description': 'Griechischer Analogcomputer aus dem 2. Jh. v.Chr. zur Berechnung astronomischer Positionen. Technologie 1000 Jahre seiner Zeit voraus.',
            'date': datetime(1, 1, 1) - timedelta(days=365*100),  # 100 v.Chr.
            'category': 'techMysteries',
            'perspectives': ['scientific', 'alternative', 'mainstream'],
            'sources': ['National Archaeological Museum Athens', 'Scientific Studies', 'X-Ray Analysis'],
            'trustLevel': 5,
            'latitude': 35.8667,
            'longitude': 23.3,
            'locationName': 'Antikythera, Griechenland',
            'tags': ['antikythera', 'antike_technologie', 'astronomie'],
        },
        {
            'title': 'Baghdad Battery - Urzeitliche Elektrizität',
            'description': 'Terrakotta-Gefäße aus dem 2. Jh. v.Chr. mit Kupfer- und Eisen-Stäben. Möglicherweise primitive galvanische Zellen mit 1-2 Volt.',
            'date': datetime(1, 1, 1) - timedelta(days=365*200),  # 200 v.Chr.
            'category': 'techMysteries',
            'perspectives': ['alternative', 'scientific', 'conspiracy'],
            'sources': ['National Museum of Iraq', 'Archaeological Studies', 'Electro-chemical Tests'],
            'trustLevel': 3,
            'latitude': 33.3128,
            'longitude': 44.3615,
            'locationName': 'Baghdad, Irak',
            'tags': ['baghdad_battery', 'antike_elektrizität'],
        },
        
        # 5. Dimensional Anomalies (Dimensionale Anomalien)
        {
            'title': 'Bermuda-Dreieck Mysterium',
            'description': 'Region zwischen Florida, Bermuda und Puerto Rico mit unerklärlichen Schiffs- und Flugzeugverschwinden. Über 50 dokumentierte Fälle seit 1945.',
            'date': datetime(1945, 12, 5),
            'category': 'dimensionalAnomalies',
            'perspectives': ['conspiracy', 'scientific', 'alternative'],
            'sources': ['US Navy Records', 'Flight 19 Investigation', 'Coast Guard Reports'],
            'trustLevel': 3,
            'latitude': 25.0,
            'longitude': -71.0,
            'locationName': 'Bermuda-Dreieck, Atlantik',
            'tags': ['bermuda', 'verschwundene_schiffe', 'magnetische_anomalien'],
        },
        {
            'title': 'Philadelphia Experiment',
            'description': 'Angeblicher US Navy-Versuch 1943, Zerstörer USS Eldridge unsichtbar zu machen. Zeugen berichten von Teleportation und fusionierten Körpern.',
            'date': datetime(1943, 10, 28),
            'category': 'dimensionalAnomalies',
            'perspectives': ['conspiracy', 'alternative'],
            'sources': ['Carlos Allende Letters', 'Witness Testimonies', 'Navy Denials'],
            'trustLevel': 2,
            'latitude': 39.9526,
            'longitude': -75.1652,
            'locationName': 'Philadelphia, Pennsylvania, USA',
            'tags': ['philadelphia_experiment', 'teleportation', 'navy'],
        },
        
        # 6. Occult Events (Okkulte Ereignisse)
        {
            'title': 'Aleister Crowleys Äon von Horus',
            'description': 'Empfang des "Liber AL vel Legis" in Kairo 1904. Grundlagentext der Thelema-Philosophie und moderner Okkultismus durch Entität "Aiwass".',
            'date': datetime(1904, 4, 8),
            'category': 'occultEvents',
            'perspectives': ['spiritual', 'alternative', 'mainstream'],
            'sources': ['Liber AL vel Legis', 'Crowleys Tagebücher', 'Thelema Documentation'],
            'trustLevel': 3,
            'latitude': 30.0444,
            'longitude': 31.2357,
            'locationName': 'Kairo, Ägypten',
            'tags': ['crowley', 'thelema', 'okkultismus'],
        },
        {
            'title': 'Fatima Sonnenwunder',
            'description': 'Über 70.000 Zeugen beobachten tanzende Sonne in Portugal 1917. Ereignis von katholischer Kirche als Marienerscheinung anerkannt.',
            'date': datetime(1917, 10, 13),
            'category': 'occultEvents',
            'perspectives': ['spiritual', 'mainstream', 'scientific'],
            'sources': ['Augenzeugenberichte', 'Zeitungsartikel', 'Kirchliche Dokumentation'],
            'trustLevel': 4,
            'latitude': 39.6317,
            'longitude': -8.6725,
            'locationName': 'Fátima, Portugal',
            'tags': ['fatima', 'marienerscheinung', 'sonnenwunder'],
        },
        
        # 7. Forbidden Knowledge (Verbotenes Wissen)
        {
            'title': 'Library of Alexandria Zerstörung',
            'description': 'Zerstörung der größten antiken Bibliothek (ca. 48 v.Chr.). Unwiederbringlicher Verlust von Wissen aus Mathematik, Astronomie, Medizin.',
            'date': datetime(1, 1, 1) - timedelta(days=365*48),  # 48 v.Chr.
            'category': 'forbiddenKnowledge',
            'perspectives': ['mainstream', 'alternative', 'spiritual'],
            'sources': ['Historische Berichte', 'Archäologische Studien', 'Antike Texte'],
            'trustLevel': 5,
            'latitude': 31.2156,
            'longitude': 29.9553,
            'locationName': 'Alexandria, Ägypten',
            'tags': ['alexandria', 'bibliothek', 'verlorenes_wissen'],
        },
        {
            'title': 'Voynich-Manuskript',
            'description': 'Mittelalterliches Manuskript in unbekannter Schrift und Sprache. Botanische und astronomische Illustrationen. Bis heute nicht entschlüsselt.',
            'date': datetime(1404, 1, 1),
            'category': 'forbiddenKnowledge',
            'perspectives': ['scientific', 'alternative', 'conspiracy'],
            'sources': ['Yale Beinecke Library', 'Carbon Dating', 'Cryptographic Analysis'],
            'trustLevel': 5,
            'latitude': 41.8781,
            'longitude': 12.4964,
            'locationName': 'Italien (vermutet)',
            'tags': ['voynich', 'manuskript', 'unentschlüsselt'],
        },
        
        # 8. UFO Fleets (UFO-Flotten)
        {
            'title': 'Nürnberger Himmelsschlacht 1561',
            'description': 'Massenhafte UFO-Sichtung über Nürnberg. Zeitgenössische Holzschnitte zeigen Kugeln, Kreuze und Zylinder am Himmel kämpfend.',
            'date': datetime(1561, 4, 14),
            'category': 'ufoFleets',
            'perspectives': ['alternative', 'conspiracy', 'mainstream'],
            'sources': ['Hans Glaser Holzschnitt', 'Stadtchroniken Nürnberg', 'Historical Records'],
            'trustLevel': 4,
            'latitude': 49.4521,
            'longitude': 11.0767,
            'locationName': 'Nürnberg, Deutschland',
            'tags': ['nürnberg', 'ufo_flotte', '1561'],
        },
        {
            'title': 'Phoenix Lights Massensichtung',
            'description': 'Tausende Zeugen sahen kilometerlange V-förmige Objekte über Arizona 1997. Militär spricht von Leuchtraketen, doch Zeugen widersprechen.',
            'date': datetime(1997, 3, 13),
            'category': 'ufoFleets',
            'perspectives': ['conspiracy', 'mainstream', 'alternative'],
            'sources': ['FAA Reports', '700+ Witness Testimonies', 'Military Response', 'Video Evidence'],
            'trustLevel': 4,
            'latitude': 33.4484,
            'longitude': -112.0740,
            'locationName': 'Phoenix, Arizona, USA',
            'tags': ['phoenix_lights', 'mass_sighting', 'v_formation'],
        },
        
        # 9. Energy Phenomena (Energie-Phänomene)
        {
            'title': 'Tunguska-Explosion',
            'description': 'Eine gewaltige Explosion in Sibirien 1908 mit der Kraft von 1000 Hiroshima-Bomben. Kein Krater gefunden, 2000 km² Wald verwüstet.',
            'date': datetime(1908, 6, 30),
            'category': 'energyPhenomena',
            'perspectives': ['scientific', 'conspiracy', 'alternative'],
            'sources': ['Wissenschaftliche Expeditionen', 'Augenzeugenberichte', 'Seismische Daten'],
            'trustLevel': 5,
            'latitude': 60.886,
            'longitude': 101.894,
            'locationName': 'Tunguska, Sibirien, Russland',
            'tags': ['tunguska', 'explosion', 'meteorit'],
        },
        {
            'title': 'HAARP Forschungsstation',
            'description': 'Hochfrequenz-Antennenprojekt zur Ionosphärenforschung in Alaska. Verschwörungstheorien über Wettermanipulation und Gedankenkontrolle.',
            'date': datetime(1993, 1, 1),
            'category': 'energyPhenomena',
            'perspectives': ['conspiracy', 'scientific', 'alternative'],
            'sources': ['US Air Force Documents', 'Scientific Papers', 'DARPA Reports'],
            'trustLevel': 3,
            'latitude': 62.3900,
            'longitude': -145.1500,
            'locationName': 'Gakona, Alaska, USA',
            'tags': ['haarp', 'ionosphäre', 'wetterkontrolle'],
        },
        
        # 10. Global Conspiracies (Globale Verschwörungen)
        {
            'title': 'Operation Paperclip - Nazi-Wissenschaftler',
            'description': 'Geheime US-Operation (1945-1990) zur Rekrutierung von über 1600 deutschen Wissenschaftlern. Viele waren NSDAP-Mitglieder oder Kriegsverbrecher.',
            'date': datetime(1945, 8, 9),
            'category': 'globalConspiracies',
            'perspectives': ['mainstream', 'conspiracy', 'scientific'],
            'sources': ['Declassified Documents', 'FOIA Files', 'Congressional Records'],
            'trustLevel': 5,
            'latitude': 38.9072,
            'longitude': -77.0369,
            'locationName': 'Washington D.C., USA',
            'tags': ['paperclip', 'nazi', 'wernher_von_braun'],
        },
        {
            'title': 'Bilderberg Konferenz',
            'description': 'Jährliches Treffen der Weltelite seit 1954. Geschlossene Konferenz ohne Pressezugang. Teilnehmer: Politiker, Banker, Industrielle.',
            'date': datetime(1954, 5, 29),
            'category': 'globalConspiracies',
            'perspectives': ['conspiracy', 'alternative', 'mainstream'],
            'sources': ['Participant Lists', 'Leaked Minutes', 'Investigative Reports'],
            'trustLevel': 4,
            'latitude': 50.8503,
            'longitude': 5.6911,
            'locationName': 'Oosterbeek, Niederlande (erstes Treffen)',
            'tags': ['bilderberg', 'elite', 'neue_weltordnung'],
        },
    ]
    
    print(f"\n📚 Erstelle {len(events)} Sample-Events...")
    
    events_collection = db.collection('events')
    
    for i, event in enumerate(events, 1):
        try:
            # Erstelle Document mit Auto-ID
            doc_ref = events_collection.add(event)
            print(f"  ✅ [{i}/{len(events)}] {event['title']}")
        except Exception as e:
            print(f"  ❌ [{i}/{len(events)}] Fehler: {e}")
    
    print(f"\n✅ Firebase Backend initialisiert mit {len(events)} Events!")
    print(f"📊 Kategorien:")
    categories = {}
    for event in events:
        cat = event['category']
        categories[cat] = categories.get(cat, 0) + 1
    
    for cat, count in sorted(categories.items()):
        print(f"   - {cat}: {count} Events")

def main():
    print("🔥 Firebase Backend Initialisierung - Weltenbibliothek")
    print("=" * 60)
    
    # Initialisiere Firebase
    db = init_firebase()
    
    # Erstelle Sample Events
    create_sample_events(db)
    
    print("\n" + "=" * 60)
    print("✨ Backend-Initialisierung abgeschlossen!")
    print("\n📝 Nächste Schritte:")
    print("   1. Öffne Firebase Console")
    print("   2. Navigiere zu Firestore Database")
    print("   3. Prüfe die 'events' Collection")
    print("   4. Starte deine Flutter App")

if __name__ == "__main__":
    main()
