#!/usr/bin/env python3
"""
Load batch events directly into D1 database with proper escaping
"""
import json
import subprocess
import sys

# Batch 1: Events 36-55 (Antike Zivilisationen & UFO Sichtungen)
batch1_events = [
    {
        "id": 36,
        "title": "Tempel von Baalbek",
        "description": "Megalithische Tempelanlage mit 1.000-Tonnen-Steinen. Wie wurden diese bewegt?",
        "latitude": 34.0061,
        "longitude": 36.2038,
        "category": "Alte Zivilisationen",
        "event_type": "ancient",
        "year": -5000,
        "date_text": "5000 v.Chr.",
        "icon_type": "temple",
        "full_description": "Die Tempelanlage von Baalbek im Libanon beherbergt die größten bearbeiteten Steinblöcke der Antike. Der Stein des Südens wiegt geschätzte 1.200 Tonnen. Drei riesige Steinblöcke, jeder über 800 Tonnen schwer, wurden präzise in 7 Meter Höhe eingesetzt. Moderne Kräne können maximal 200 Tonnen heben. Die römische Geschichtsschreibung schreibt den Tempel Jupiter zu, doch die megalithischen Fundamente sind älter - möglicherweise 7.000-9.000 Jahre. Lokale Legenden sprechen von Riesen als Erbauern.",
        "sources": json.dumps([
            {"title": "Baalbek Megalithic Enigma", "author": "Ralph Ellis", "year": 2013},
            {"title": "Technology of the Gods", "author": "David Childress", "year": 2000}
        ]),
        "keywords": json.dumps(["Baalbek", "Megalith", "Antike Technologie", "Libanon", "Riesen", "Unmögliche Konstruktion"]),
        "evidence_level": "documented"
    },
    {
        "id": 37,
        "title": "Bosnische Pyramiden",
        "description": "Kontroverse Pyramiden-Strukturen in Bosnien, möglicherweise 29.000 Jahre alt.",
        "latitude": 43.9775,
        "longitude": 18.1764,
        "category": "Alte Zivilisationen",
        "event_type": "ancient",
        "year": -27000,
        "date_text": "27.000 v.Chr.",
        "icon_type": "pyramid",
        "full_description": "2005 entdeckte Dr. Semir Osmanagić geometrisch geformte Hügel bei Visoko. Die Sonnenpyramide wäre mit 220 Metern höher als Gizeh. Untersuchungen zeigen präzise 45-Grad-Ausrichtung, künstliche Betonschichten, unterirdische Tunnelsysteme und Ultraschall-Emissionen von 28 kHz. Radiokarbondatierung ergab ein Alter von bis zu 29.000 Jahren. Messungen zeigen ungewöhnliche elektromagnetische Felder.",
        "sources": json.dumps([
            {"title": "The Bosnian Pyramid Complex", "author": "Semir Osmanagić", "year": 2006}
        ]),
        "keywords": json.dumps(["Bosnien", "Pyramiden", "Kontrovers", "Ultraschall", "Prähistorisch", "Energie"]),
        "evidence_level": "speculative"
    },
    {
        "id": 38,
        "title": "Derinkuyu Unterirdische Stadt",
        "description": "Riesige unterirdische Stadt in der Türkei für 20.000 Menschen. Warum gebaut?",
        "latitude": 38.3733,
        "longitude": 34.7356,
        "category": "Alte Zivilisationen",
        "event_type": "ancient",
        "year": -1400,
        "date_text": "14. Jh. v.Chr.",
        "icon_type": "underground",
        "full_description": "18 Stockwerke tief erstreckt sich diese unterirdische Stadt in Kappadokien für 20.000 Menschen. Aus vulkanischem Tuffstein gemeißelt, verfügt sie über Belüftungsschächte bis 85 Meter tief, runde Steintüren als Verteidigung, Wasserbrunnen, Schulen und Ställe. Offizielle Erklärung: Schutz vor Invasoren. Alternative Theorien: Zuflucht vor kataklysmischen Ereignissen oder kosmischer Strahlung. Verbindungen zu über 200 anderen unterirdischen Städten nachgewiesen.",
        "sources": json.dumps([
            {"title": "Underground Cities of Cappadocia", "author": "Omer Demir", "year": 2015}
        ]),
        "keywords": json.dumps(["Türkei", "Unterirdische Stadt", "Kappadokien", "Antike", "Katastrophe", "Schutz"]),
        "evidence_level": "documented"
    },
    {
        "id": 39,
        "title": "Yonaguni Unterwasser-Monument",
        "description": "Riesige Unterwasser-Strukturen vor Japan. Natürlich oder künstlich?",
        "latitude": 24.4368,
        "longitude": 123.0034,
        "category": "Alte Zivilisationen",
        "event_type": "ancient",
        "year": -8000,
        "date_text": "8000 v.Chr.",
        "icon_type": "underwater",
        "full_description": "1987 entdeckte Taucher Kihachiro Aratake vor Japan massive Unterwasser-Strukturen: Terrassen, Stufen, Straßen und eine riesige Pyramide. Merkmale: rechte Winkel, parallele Treppen, eingravierte Symbole. Hauptmonument: 50m breit, 200m lang, 27m hoch. Falls künstlich, wurde die Stadt vor 10.000-12.000 Jahren erbaut, als der Meeresspiegel 40 Meter niedriger war - älter als Gizeh. Einige Forscher sehen es als Überrest des legendären Kontinents Mu.",
        "sources": json.dumps([
            {"title": "Underworld", "author": "Graham Hancock", "year": 2002}
        ]),
        "keywords": json.dumps(["Japan", "Unterwasser", "Versunkene Stadt", "Eiszeit", "Pazifik", "Mu"]),
        "evidence_level": "speculative"
    },
    {
        "id": 40,
        "title": "Antikythera-Mechanismus",
        "description": "2.000 Jahre alter Computer-Mechanismus. Technologie die nicht existieren sollte.",
        "latitude": 35.8681,
        "longitude": 23.3114,
        "category": "Alte Astronauten",
        "event_type": "ancient",
        "year": -100,
        "date_text": "100 v.Chr.",
        "icon_type": "mechanism",
        "full_description": "1901 aus einem griechischen Schiffswrack geborgen, ist dieser astronomische Rechner aus Bronze mit über 30 Zahnrädern das komplexeste technische Gerät der Antike. Funktionen: Vorhersage von Finsternissen, Planetenbewegungen, Olympische Spiele-Zyklus, Mondphasen. Die Feinheit der Zahnräder entspricht eher der Renaissance. Ähnliche Komplexität erreichte Europa erst im 14. Jahrhundert - 1.400 Jahre später!",
        "sources": json.dumps([
            {"title": "Decoding the Heavens", "author": "Jo Marchant", "year": 2008},
            {"title": "The Antikythera Mechanism", "author": "Derek de Solla Price", "year": 1974}
        ]),
        "keywords": json.dumps(["Antikythera", "Computer", "Griechisch", "Astronomie", "Technologie", "Anachronismus"]),
        "evidence_level": "proven"
    }
]

def escape_sql(value):
    """Escape single quotes for SQL"""
    if value is None:
        return 'NULL'
    if isinstance(value, str):
        return value.replace("'", "''")
    return str(value)

def insert_event(event):
    """Insert single event into database"""
    sql = f"""
    INSERT INTO events (
        id, title, description, latitude, longitude, category, event_type, 
        year, date_text, icon_type, full_description, sources, keywords, evidence_level
    ) VALUES (
        {event['id']},
        '{escape_sql(event['title'])}',
        '{escape_sql(event['description'])}',
        {event['latitude']},
        {event['longitude']},
        '{escape_sql(event['category'])}',
        '{escape_sql(event['event_type'])}',
        {event['year']},
        '{escape_sql(event['date_text'])}',
        '{escape_sql(event['icon_type'])}',
        '{escape_sql(event['full_description'])}',
        '{escape_sql(event['sources'])}',
        '{escape_sql(event['keywords'])}',
        '{escape_sql(event['evidence_level'])}'
    );
    """
    
    cmd = [
        'npx', 'wrangler', 'd1', 'execute', 'weltenbibliothek_db_v2',
        '--local', '--command', sql
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, cwd='/home/user/webapp')
    
    if result.returncode != 0:
        print(f"❌ Error inserting event {event['id']}: {event['title']}")
        print(f"   {result.stderr}")
        return False
    else:
        print(f"✅ Inserted event {event['id']}: {event['title']}")
        return True

def main():
    print("🚀 Loading Batch 1 events (36-40) - Testing first 5 events...\n")
    
    success_count = 0
    fail_count = 0
    
    for event in batch1_events:
        if insert_event(event):
            success_count += 1
        else:
            fail_count += 1
    
    print(f"\n📊 Results: {success_count} success, {fail_count} failed")
    
    if fail_count == 0:
        print("✅ All test events loaded successfully!")
        print("   Ready to load remaining 40 events...")
    else:
        print("❌ Some events failed. Check errors above.")
        sys.exit(1)

if __name__ == '__main__':
    main()
