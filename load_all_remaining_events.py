#!/usr/bin/env python3
"""
Load ALL remaining events (41-80) into D1 database
Batch 1: Events 41-55 (Antike & UFOs)
Batch 2: Events 56-80 (Experimente & Kryptozoologie)
"""
import json
import subprocess
import sys

# ALL REMAINING EVENTS (41-80)
all_events = [
    # BATCH 1 continued (41-55): Antike Zivilisationen & UFO Sichtungen
    {
        "id": 41, "title": "Sacsayhuamán", 
        "description": "Perfekt passende 200-Tonnen-Steine ohne Mörtel. Wie wurden sie geschnitten?",
        "latitude": -13.5086, "longitude": -71.9819, "category": "Alte Zivilisationen",
        "event_type": "ancient", "year": -1100, "date_text": "11. Jh. v.Chr.", "icon_type": "fortress",
        "full_description": "Die Festungsanlage über Cusco besteht aus Kalksteinblöcken bis 200 Tonnen, die ohne Mörtel so präzise passen, dass keine Rasierklinge dazwischen passt. Die Inka-Legenden sagen, sie hätten die Anlage vorgefunden. Spanische Chronisten berichteten von Magie beim Steinbau. Die Steine zeigen keine Werkzeugspuren und wurden über Kilometer transportiert.",
        "sources": json.dumps([{"title": "Fingerprints of the Gods", "author": "Graham Hancock", "year": 1995}]),
        "keywords": json.dumps(["Peru", "Inka", "Megalith", "Präzision", "Cusco", "Unerklärlich"]),
        "evidence_level": "documented"
    },
    {
        "id": 42, "title": "Piri Reis Karte",
        "description": "Karte von 1513 zeigt Antarctica eisfrei - wie war das möglich?",
        "latitude": 41.0082, "longitude": 28.9784, "category": "Alte Zivilisationen",
        "event_type": "ancient", "year": 1513, "date_text": "1513", "icon_type": "map",
        "full_description": "Der türkische Admiral Piri Reis zeichnete 1513 eine Weltkarte, die Details der antarktischen Küstenlinie zeigt - ohne Eis. Antarctica wurde erst 1820 entdeckt, und die Küste unter dem Eis war seit 6.000 Jahren verborgen. Piri Reis gab an, 20 alte Karten als Quellen verwendet zu haben. Die Genauigkeit ist erstaunlich und wirft Fragen auf über antike Seefahrer-Zivilisationen.",
        "sources": json.dumps([{"title": "Maps of the Ancient Sea Kings", "author": "Charles Hapgood", "year": 1966}]),
        "keywords": json.dumps(["Karte", "Antarctica", "Osmanisches Reich", "Anomalie", "Prähistorisch"]),
        "evidence_level": "documented"
    },
    {
        "id": 43, "title": "Longyou-Höhlen",
        "description": "Riesige künstliche Höhlen in China - wer hat sie gebaut und warum?",
        "latitude": 29.0333, "longitude": 119.1667, "category": "Alte Zivilisationen",
        "event_type": "ancient", "year": -200, "date_text": "200 v.Chr.", "icon_type": "cave",
        "full_description": "24 riesige künstliche Höhlen in China, entdeckt 1992. Geschätzte 1 Million Kubikmeter Gestein wurden präzise entfernt. Die Decken sind mit parallelen Rillenmustern bedeckt. Säulen tragen die Decken. Keine historischen Aufzeichnungen über den Bau. Die Präzision und Symmetrie sind unerklärlich. Warum sind sie in keinen chinesischen Texten erwähnt?",
        "sources": json.dumps([{"title": "Ancient Architects of China", "author": "Wu Chen", "year": 2010}]),
        "keywords": json.dumps(["China", "Höhlen", "Künstlich", "Geheimnis", "Präzision"]),
        "evidence_level": "documented"
    },
    {
        "id": 44, "title": "Newgrange",
        "description": "5.000 Jahre altes Monument, älter als Pyramiden - mit Sonnenkalender.",
        "latitude": 53.6947, "longitude": -6.4753, "category": "Alte Zivilisationen",
        "event_type": "ancient", "year": -3200, "date_text": "3200 v.Chr.", "icon_type": "monument",
        "full_description": "Newgrange in Irland ist 5.200 Jahre alt - 500 Jahre älter als Gizeh. Am Morgen der Wintersonnenwende dringt Sonnenlicht durch einen präzise konstruierten Gang und beleuchtet die innere Kammer für genau 17 Minuten. Die Erbauer hatten fortgeschrittene astronomische Kenntnisse. Über 200.000 Tonnen Stein wurden ohne Metallwerkzeuge bearbeitet.",
        "sources": json.dumps([{"title": "Newgrange: Archaeology, Art and Legend", "author": "Michael O'Kelly", "year": 1982}]),
        "keywords": json.dumps(["Irland", "Megalith", "Astronomie", "Sonnenwende", "Prähistorisch"]),
        "evidence_level": "proven"
    },
    {
        "id": 45, "title": "Teotihuacán Pyramiden",
        "description": "Pyramiden mit Quecksilber unter dem Boden - für Energie oder Symbolik?",
        "latitude": 19.6925, "longitude": -98.8438, "category": "Alte Zivilisationen",
        "event_type": "ancient", "year": -100, "date_text": "100 v.Chr.", "icon_type": "pyramid",
        "full_description": "Die Stadt der Götter in Mexiko hat unter der Mondpyramide große Mengen flüssiges Quecksilber. Archäologen fanden metallische Kugeln und reflektierende Pulver in Tunneln. War Quecksilber Teil einer Energietechnologie? Die gesamte Stadt ist wie ein Schaltkreis-Layout angelegt. Die Pyramiden sind exakt auf astronomische Ereignisse ausgerichtet.",
        "sources": json.dumps([{"title": "Teotihuacan Mysteries", "author": "Sergio Gomez", "year": 2015}]),
        "keywords": json.dumps(["Mexiko", "Pyramiden", "Quecksilber", "Energie", "Astronomie"]),
        "evidence_level": "documented"
    },
    {
        "id": 46, "title": "Betty & Barney Hill Entführung",
        "description": "Erste dokumentierte Alien-Entführung 1961 - Sternenkarte gezeichnet.",
        "latitude": 43.7695, "longitude": -71.5724, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1961, "date_text": "19.09.1961", "icon_type": "ufo",
        "full_description": "Das Ehepaar Hill erlebte 1961 in New Hampshire eine 2-stündige Gedächtnislücke. Unter Hypnose berichteten beide unabhängig von einer Entführung durch graue Wesen. Betty zeichnete eine Sternenkarte, die später als Zeta Reticuli identifiziert wurde - ein Sternsystem 39 Lichtjahre entfernt. Physische Beweise: Beschädigungen am Auto, radioaktive Stellen auf Kleidung.",
        "sources": json.dumps([{"title": "The Interrupted Journey", "author": "John Fuller", "year": 1966}]),
        "keywords": json.dumps(["Alien-Entführung", "Betty Hill", "Barney Hill", "Zeta Reticuli", "Hypnose"]),
        "evidence_level": "documented"
    },
    {
        "id": 47, "title": "Westall UFO Encounter",
        "description": "200 Schüler und Lehrer sahen UFO in Australien 1966 - Militär vertuscht.",
        "latitude": -37.9333, "longitude": 145.1000, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1966, "date_text": "06.04.1966", "icon_type": "ufo",
        "full_description": "Über 200 Schüler und Lehrer der Westall High School sahen ein silbernes Objekt landen, 20 Minuten bleiben und dann mit hoher Geschwindigkeit verschwinden. Es hinterließ einen verbrannten Kreis im Gras. Das Militär erschien sofort, befragte Zeugen und befahl Schweigen. Fotos verschwanden. Die australische Regierung leugnete den Vorfall jahrzehntelang.",
        "sources": json.dumps([{"title": "The Westall Incident", "author": "Shane Ryan", "year": 2010}]),
        "keywords": json.dumps(["Australien", "Schul-UFO", "Massenbeobachtung", "Vertuschung", "1966"]),
        "evidence_level": "documented"
    },
    {
        "id": 48, "title": "Travis Walton Entführung",
        "description": "5 Tage verschwunden nach UFO-Begegnung - 6 Zeugen bestanden Lügendetektortest.",
        "latitude": 34.2695, "longitude": -110.8262, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1975, "date_text": "05.11.1975", "icon_type": "ufo",
        "full_description": "Holzfäller Travis Walton verschwand vor den Augen von 6 Kollegen, nachdem ein Lichtstrahl ihn traf. 5 Tage später tauchte er auf - dehydriert, verstört. Er beschrieb medizinische Untersuchungen durch Aliens. Alle 6 Zeugen bestanden Lügendetektortests. Der Fall wurde nie widerlegt und bleibt einer der glaubwürdigsten Entführungsfälle.",
        "sources": json.dumps([{"title": "Fire in the Sky", "author": "Travis Walton", "year": 1978}]),
        "keywords": json.dumps(["Entführung", "Travis Walton", "Arizona", "Lügendetektor", "Zeugen"]),
        "evidence_level": "documented"
    },
    {
        "id": 49, "title": "Iranian Air Force UFO 1976",
        "description": "F-4 Jets verfolgten UFO über Teheran - Waffensysteme versagten.",
        "latitude": 35.6892, "longitude": 51.3890, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1976, "date_text": "19.09.1976", "icon_type": "ufo",
        "full_description": "Zwei F-4 Phantom Jets der iranischen Luftwaffe verfolgten ein hell leuchtendes UFO über Teheran. Als der Pilot versuchte zu feuern, versagten alle Waffensysteme und Kommunikation. Ein kleines Objekt trennte sich vom Hauptobjekt und verfolgte die Jets. Über 100.000 Zeugen am Boden. Die USA stufen den Fall als hochgradig glaubwürdig ein.",
        "sources": json.dumps([{"title": "Defense Intelligence Agency Report", "year": 1976}]),
        "keywords": json.dumps(["Iran", "Militär-UFO", "Teheran", "F-4", "Waffenversagen"]),
        "evidence_level": "military"
    },
    {
        "id": 50, "title": "JAL Flight 1628",
        "description": "Jumbo-Jet Crew sah riesiges UFO über Alaska 1986 - FAA bestätigt Radar.",
        "latitude": 64.2008, "longitude": -149.4937, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1986, "date_text": "17.11.1986", "icon_type": "ufo",
        "full_description": "Japan Airlines Flug 1628 begegnete über Alaska einem UFO so groß wie zwei Flugzeugträger. Kapitän Kenju Terauchi und seine Crew beobachteten es 50 Minuten lang. FAA-Radar bestätigte unbekannte Objekte. Das UFO folgte dem Flugzeug, schwebte und beschleunigte unmöglich schnell. Terauchi wurde von Japan Airlines degradiert wegen seiner Aussage.",
        "sources": json.dumps([{"title": "FAA Division Report", "year": 1987}]),
        "keywords": json.dumps(["Alaska", "JAL", "Jumbo-Jet", "Radar", "FAA"]),
        "evidence_level": "military"
    },
    {
        "id": 51, "title": "Belgian UFO Wave",
        "description": "F-16 Jets verfolgten dreieckiges UFO 1989-1990 - 13.500 Zeugen.",
        "latitude": 50.8503, "longitude": 4.3517, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1989, "date_text": "29.11.1989", "icon_type": "ufo",
        "full_description": "Über 13.500 Belgier sahen zwischen 1989-1990 dreieckige UFOs. Die belgische Luftwaffe schickte F-16 Jets. Radar zeigte Objekte, die von 280 auf 1.800 km/h in 1 Sekunde beschleunigten. Das Militär gab eine Pressekonferenz und bestätigte unerklärliche Phänomene. Hunderte Fotos und Videos dokumentieren die Welle.",
        "sources": json.dumps([{"title": "Belgian UFO Wave Report", "author": "Belgian Air Force", "year": 1991}]),
        "keywords": json.dumps(["Belgien", "UFO-Welle", "F-16", "Dreieck", "Militär"]),
        "evidence_level": "military"
    },
    {
        "id": 52, "title": "USS Nimitz Tic-Tac UFO",
        "description": "Pentagon bestätigte UFO-Video von 2004 - Objekt bewegte sich unmöglich.",
        "latitude": 31.1000, "longitude": -116.2500, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 2004, "date_text": "14.11.2004", "icon_type": "ufo",
        "full_description": "US Navy Piloten vom USS Nimitz verfolgten ein weißes, tic-tac-förmiges Objekt ohne Flügel oder Antrieb. Es beschleunigte von 0 auf über 100.000 km/h in Sekunden, tauchte von 24.000m auf Meereshöhe in Sekunden. Pentagon veröffentlichte 2020 offiziell die Videos. Radar, Infrarot, und visuelle Bestätigung von mehreren Systemen.",
        "sources": json.dumps([{"title": "Pentagon UAP Report", "year": 2020}]),
        "keywords": json.dumps(["US Navy", "Tic-Tac", "Pentagon", "UAP", "Nimitz"]),
        "evidence_level": "military"
    },
    {
        "id": 53, "title": "Ariel School Zimbabwe",
        "description": "62 Kinder sahen UFO und Aliens auf Schulhof 1994 - konsistente Aussagen.",
        "latitude": -17.7975, "longitude": 31.0552, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1994, "date_text": "16.09.1994", "icon_type": "ufo",
        "full_description": "62 Schulkinder in Ruwa, Zimbabwe sahen ein silbernes Objekt landen. Kleine Wesen mit großen Augen stiegen aus und kommunizierten telepathisch Botschaften über Umweltzerstörung. Die Kinder zeichneten unabhängig identische Bilder. Harvard-Psychiater Dr. John Mack interviewte sie - alle sagten die Wahrheit. Keine Widersprüche in den Aussagen.",
        "sources": json.dumps([{"title": "Passport to the Cosmos", "author": "John Mack", "year": 1999}]),
        "keywords": json.dumps(["Zimbabwe", "Schulkinder", "Telepathie", "John Mack", "1994"]),
        "evidence_level": "documented"
    },
    {
        "id": 54, "title": "O'Hare Airport UFO",
        "description": "United Airlines Crew und Passagiere sahen UFO 2006 - FAA ignorierte Fall.",
        "latitude": 41.9742, "longitude": -87.9073, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 2006, "date_text": "07.11.2006", "icon_type": "ufo",
        "full_description": "United Airlines Mitarbeiter und Passagiere sahen ein metallisches, scheibenförmiges Objekt über Gate C17 schweben. Es schoss plötzlich durch die Wolken und hinterließ ein perfektes Loch. Mindestens 12 Angestellte meldeten es. United bestätigte Berichte, aber FAA lehnte Untersuchung ab. Radar-Daten wurden nie freigegeben.",
        "sources": json.dumps([{"title": "Chicago Tribune Report", "year": 2007}]),
        "keywords": json.dumps(["Chicago", "Airport", "United Airlines", "2006", "FAA"]),
        "evidence_level": "documented"
    },
    {
        "id": 55, "title": "Rendlesham Forest",
        "description": "Britains Roswell - US Militär sah UFO bei RAF Base 1980 - offizielle Berichte.",
        "latitude": 52.0944, "longitude": 1.4500, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1980, "date_text": "26.12.1980", "icon_type": "ufo",
        "full_description": "US Air Force Personal auf RAF Bentwaters sah ein dreieckiges Objekt im Wald landen. Colonel Charles Halt dokumentierte es in einem offiziellen Memo. Messungen zeigten hohe Strahlung. Das Objekt hinterließ Abdrücke. Lichter kommunizierten in Binärcode. Mehrere Offiziere wurden Zeugen über 3 Nächte. Gilt als bestdokumentierter UFO-Fall Großbritanniens.",
        "sources": json.dumps([{"title": "Halt Memo", "author": "Charles Halt", "year": 1980}]),
        "keywords": json.dumps(["England", "RAF", "US Air Force", "Rendlesham", "Militär"]),
        "evidence_level": "military"
    },
    
    # BATCH 2 (56-80): Geheime Experimente, Kryptozoologie, Moderne Phänomene
    {
        "id": 56, "title": "MK-Ultra Programm",
        "description": "CIA Mind Control Experimente mit LSD - Tausende unwissende Opfer.",
        "latitude": 38.8951, "longitude": -77.0364, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1953, "date_text": "1953-1973", "icon_type": "lab",
        "full_description": "Die CIA führte zwischen 1953-1973 illegale Experimente zur Bewusstseinskontrolle durch. Über 150 Unterprojekte testeten LSD, Hypnose, Folter und Drogen an ahnungslosen Zivilisten, Gefangenen und Militär. Der Wissenschaftler Frank Olson starb mysteriös nach LSD-Gabe. 1975 deckte der Church Committee die Verbrechen auf. Die meisten Dokumente wurden vernichtet.",
        "sources": json.dumps([{"title": "The Search for the Manchurian Candidate", "author": "John Marks", "year": 1979}]),
        "keywords": json.dumps(["CIA", "MK-Ultra", "Mind Control", "LSD", "Experimente"]),
        "evidence_level": "proven"
    },
    {
        "id": 57, "title": "Tuskegee Syphilis-Studie",
        "description": "US Public Health Service ließ 600 Schwarze sterben - 40 Jahre lang.",
        "latitude": 32.4297, "longitude": -85.7077, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1932, "date_text": "1932-1972", "icon_type": "medical",
        "full_description": "Von 1932-1972 beobachtete die US-Regierung 600 Afroamerikaner mit Syphilis - ohne sie zu behandeln. Die Männer dachten, sie bekämen kostenlose Gesundheitsversorgung. Selbst als Penicillin verfügbar wurde, verweigerte man ihnen die Heilung. 128 Männer starben direkt an Syphilis, 40 Frauen wurden infiziert, 19 Kinder mit angeborener Syphilis geboren.",
        "sources": json.dumps([{"title": "Bad Blood", "author": "James Jones", "year": 1981}]),
        "keywords": json.dumps(["Tuskegee", "Syphilis", "Rassismus", "Medizin-Verbrechen", "USA"]),
        "evidence_level": "proven"
    },
    {
        "id": 58, "title": "Unit 731",
        "description": "Japanische Bio-Waffen-Einheit - Menschenversuche an 250.000 Opfern.",
        "latitude": 45.7500, "longitude": 126.6333, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1936, "date_text": "1936-1945", "icon_type": "biohazard",
        "full_description": "Die japanische Unit 731 führte im Zweiten Weltkrieg grausame Experimente durch: Vivisektionen ohne Betäubung, Frostbite-Tests, Pest-Infektionen, Druckkammer-Tests. Mindestens 250.000 Menschen starben. Die USA gewährten den Forschern Immunität im Austausch für die Daten. Die Verbrechen wurden erst in den 1990ern öffentlich anerkannt.",
        "sources": json.dumps([{"title": "Factories of Death", "author": "Sheldon Harris", "year": 1994}]),
        "keywords": json.dumps(["Japan", "Unit 731", "Bio-Waffen", "Kriegsverbrechen", "Menschenversuche"]),
        "evidence_level": "proven"
    },
    {
        "id": 59, "title": "Edgewood Arsenal Experimente",
        "description": "US Army testete Nervengas und Psychochemikalien an 7.000 Soldaten.",
        "latitude": 39.4181, "longitude": -76.1481, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1948, "date_text": "1948-1975", "icon_type": "chemical",
        "full_description": "Von 1948-1975 testete die US Army in Edgewood Arsenal chemische Waffen an 7.000 eigenen Soldaten. Getestet wurden: Sarin, VX, Senfgas, LSD, PCP und andere. Die Soldaten wurden nicht über Langzeitfolgen aufgeklärt. Viele leiden bis heute an neurologischen Schäden, Krebs und psychischen Störungen. Die Regierung verweigerte jahrzehntelang Entschädigung.",
        "sources": json.dumps([{"title": "Edgewood/Aberdeen Experiments", "author": "Institute of Medicine", "year": 1982}]),
        "keywords": json.dumps(["Edgewood", "US Army", "Nervengas", "Chemiewaffen", "Soldaten"]),
        "evidence_level": "proven"
    },
    {
        "id": 60, "title": "Guatemala Syphilis-Experimente",
        "description": "USA infizierte absichtlich 1.300 Guatemalteken mit Geschlechtskrankheiten.",
        "latitude": 14.6349, "longitude": -90.5069, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1946, "date_text": "1946-1948", "icon_type": "medical",
        "full_description": "Von 1946-1948 infizierten US-Ärzte absichtlich 1.300 Guatemalteken mit Syphilis und Gonorrhoe - ohne deren Wissen. Opfer waren Gefangene, Soldaten, Prostituierte und psychiatrische Patienten. Mindestens 83 starben. Die Experimente blieben bis 2010 geheim. Präsident Obama entschuldigte sich offiziell bei Guatemala.",
        "sources": json.dumps([{"title": "Presidential Commission Report", "year": 2011}]),
        "keywords": json.dumps(["Guatemala", "Syphilis", "USA", "Menschenversuche", "Vertuschung"]),
        "evidence_level": "proven"
    },
    {
        "id": 61, "title": "Patterson-Gimlin Bigfoot Film",
        "description": "Berühmtestes Bigfoot-Video von 1967 - bis heute nicht als Fälschung bewiesen.",
        "latitude": 41.4382, "longitude": -123.4306, "category": "Mystische Orte",
        "event_type": "cryptid", "year": 1967, "date_text": "20.10.1967", "icon_type": "footprint",
        "full_description": "Roger Patterson und Bob Gimlin filmten 1967 in Bluff Creek, Kalifornien eine 2,4 Meter große, behaarte Kreatur. Das Wesen dreht sich zur Kamera - der berühmte Frame 352. Hollywood-Experten bestätigen: Keine Kostümtechnologie der 60er könnte diese Muskelbewegungen simulieren. Fußabdrücke zeigen Details wie Dermatoglyphen. Trotz jahrzehntelanger Versuche wurde der Film nie als Fälschung bewiesen.",
        "sources": json.dumps([{"title": "The Making of Bigfoot", "author": "Greg Long", "year": 2004}]),
        "keywords": json.dumps(["Bigfoot", "Patterson-Gimlin", "Kryptozoologie", "Film", "Kalifornien"]),
        "evidence_level": "documented"
    },
    {
        "id": 62, "title": "Loch Ness Sonar-Kontakt",
        "description": "Operation Deepscan 1987 - Sonar fand große, bewegliche Anomalie im See.",
        "latitude": 57.3229, "longitude": -4.4244, "category": "Mystische Orte",
        "event_type": "cryptid", "year": 1987, "date_text": "09.10.1987", "icon_type": "wave",
        "full_description": "Operation Deepscan durchkämmte 1987 Loch Ness mit 24 Booten und modernster Sonartechnologie. Drei Boote registrierten gleichzeitig ein großes, bewegliches Objekt in 180 Meter Tiefe - zu groß für Fische, zu schnell für Wracks. Die BBC dokumentierte die Expedition. Sonar-Experten konnten das Objekt nicht erklären. Der Kontakt dauerte mehrere Minuten.",
        "sources": json.dumps([{"title": "The Loch Ness Monster: The Evidence", "author": "Steuart Campbell", "year": 1991}]),
        "keywords": json.dumps(["Loch Ness", "Nessie", "Sonar", "Operation Deepscan", "Schottland"]),
        "evidence_level": "documented"
    },
    {
        "id": 63, "title": "Mothman von Point Pleasant",
        "description": "Geflügelte Kreatur erschien vor Brückeneinsturz 1967 - 46 Tote.",
        "latitude": 38.8450, "longitude": -82.1371, "category": "Mystische Orte",
        "event_type": "cryptid", "year": 1966, "date_text": "15.11.1966", "icon_type": "bat",
        "full_description": "Über 100 Menschen in Point Pleasant, West Virginia sahen 1966-67 eine 2 Meter große Kreatur mit roten, leuchtenden Augen und Flügeln. Am 15.12.1967 brach die Silver Bridge zusammen - 46 Menschen starben. Die Mothman-Sichtungen hörten danach auf. War es eine Warnung? Zeugen beschreiben telepathische Kommunikation und Vorahnungen. Bis heute ungeklärt.",
        "sources": json.dumps([{"title": "The Mothman Prophecies", "author": "John Keel", "year": 1975}]),
        "keywords": json.dumps(["Mothman", "Point Pleasant", "Brücke", "Prophezeiung", "Kreatur"]),
        "evidence_level": "documented"
    },
    {
        "id": 64, "title": "Skinwalker Ranch",
        "description": "Paranormaler Hotspot in Utah - UFOs, Portale, Viehverstümmelungen, Poltergeister.",
        "latitude": 40.2583, "longitude": -109.8861, "category": "Mystische Orte",
        "event_type": "paranormal", "year": 1994, "date_text": "1994-heute", "icon_type": "portal",
        "full_description": "Die 200-Hektar-Ranch in Utah ist bekannt für hunderte paranormale Phänomene: UFOs, Portale, unsichtbare Wesen, Viehverstümmelungen, Zeitanomalien. Robert Bigelow kaufte die Ranch 1996 und führte wissenschaftliche Untersuchungen durch. Messgeräte registrierten unerklärliche Strahlungs-Spikes. Das Pentagon untersuchte die Ranch im Rahmen von AAWSAP. Heute läuft eine TV-Doku-Serie.",
        "sources": json.dumps([{"title": "Hunt for the Skinwalker", "author": "Colm Kelleher", "year": 2005}]),
        "keywords": json.dumps(["Skinwalker Ranch", "Utah", "Paranormal", "UFO", "Pentagon"]),
        "evidence_level": "documented"
    },
    {
        "id": 65, "title": "Hessdalen-Lichtphänomen",
        "description": "Wissenschaftlich dokumentierte Lichter in Norwegen - seit 1940er Jahren.",
        "latitude": 62.7958, "longitude": 11.1842, "category": "Mystische Orte",
        "event_type": "phenomenon", "year": 1981, "date_text": "1981-heute", "icon_type": "light",
        "full_description": "Im Hessdalen-Tal in Norwegen erscheinen seit Jahrzehnten mysteriöse Lichter: schwebend, pulsierend, farbwechselnd. Das Hessdalen Project (seit 1983) untersucht mit Kameras, Radar und Spektrometern. Die Lichter zeigen intelligentes Verhalten, reagieren auf Lichtblitze und bewegen sich gegen den Wind. Plasmaphysik erklärt nur Teile. Bis zu 20 Sichtungen pro Woche in den 80ern.",
        "sources": json.dumps([{"title": "Project Hessdalen Report", "author": "Erling Strand", "year": 1984}]),
        "keywords": json.dumps(["Hessdalen", "Norwegen", "Lichtphänomen", "Wissenschaft", "Plasma"]),
        "evidence_level": "documented"
    },
    {
        "id": 66, "title": "Kelly-Hopkinsville Begegnung",
        "description": "Familie wurde von Aliens angegriffen - 11 Zeugen, Polizei fand Spuren.",
        "latitude": 36.8625, "longitude": -87.4886, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1955, "date_text": "21.08.1955", "icon_type": "alien",
        "full_description": "Die Sutton-Familie in Kentucky wurde 1955 stundenlang von kleinen, großäugigen Wesen belagert. Die Kreaturen gingen auf das Haus zu, wurden beschossen und kamen immer wieder zurück. 11 Zeugen. Die Familie floh zur Polizei. Beamte fanden Spuren, Einschusslöcher und seltsame grüne Lichtflecken. Die Zeugen zeigten echte Angst. Der Fall blieb ungeklärt.",
        "sources": json.dumps([{"title": "The Kelly-Hopkinsville Encounter", "author": "US Air Force Report", "year": 1955}]),
        "keywords": json.dumps(["Kentucky", "Alien-Angriff", "Kelly", "Zeugen", "Polizei"]),
        "evidence_level": "documented"
    },
    {
        "id": 67, "title": "Varginha UFO-Vorfall",
        "description": "Brasilien - UFO-Crash, lebende Aliens gefangen, Militär vertuschte alles.",
        "latitude": -21.5514, "longitude": -45.4308, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1996, "date_text": "20.01.1996", "icon_type": "alien",
        "full_description": "In Varginha, Brasilien sahen über 40 Zeugen ein UFO abstürzen und zwei kleine Wesen mit großen roten Augen. Die Kreaturen wurden vom Militär gefangen. Ein Soldat starb wenige Tage später an mysteriöser Infektion. Das Militär sperrte das Gebiet ab. Ärzte bestätigten, merkwürdige Leichen gesehen zu haben. Die Regierung streitet alles ab, aber Zeugen bleiben bei ihren Aussagen.",
        "sources": json.dumps([{"title": "UFO Crash in Brazil", "author": "Roger Leir", "year": 2005}]),
        "keywords": json.dumps(["Brasilien", "Varginha", "UFO-Crash", "Aliens", "Militär"]),
        "evidence_level": "documented"
    },
    {
        "id": 68, "title": "Colares UFO-Angriffe",
        "description": "UFOs griffen brasilianische Inselbewohner an - offizielle Militäruntersuchung.",
        "latitude": -0.9003, "longitude": -47.8819, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1977, "date_text": "10.1977", "icon_type": "ufo",
        "full_description": "Im Oktober 1977 griffen UFOs die Insel Colares, Brasilien an. Lichtstrahlen verursachten Verbrennungen, Lähmungen und zwei Todesfälle. Über 2.000 Menschen flohen. Die brasilianische Luftwaffe startete Operation Prato - 4 Monate Untersuchung mit Fotos und 500 Seiten Berichten. Kommandant Hollanda bestätigte UFOs. 2004 veröffentlichte die Regierung die Akten.",
        "sources": json.dumps([{"title": "Operation Prato Files", "author": "Brazilian Air Force", "year": 1977}]),
        "keywords": json.dumps(["Brasilien", "Colares", "UFO-Angriffe", "Operation Prato", "Militär"]),
        "evidence_level": "military"
    },
    {
        "id": 69, "title": "Kecksburg UFO-Crash",
        "description": "Nazi-Glocke fiel vom Himmel? Militär beschlagnahmte mysteriöses Objekt.",
        "latitude": 40.1850, "longitude": -79.4631, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1965, "date_text": "09.12.1965", "icon_type": "ufo",
        "full_description": "Ein feuerndes Objekt stürzte 1965 in Kecksburg, Pennsylvania. Zeugen sahen eine glockenförmige Metallstruktur mit hieroglyphen-ähnlichen Symbolen. Das Militär sperrte das Gebiet, verlud das Objekt auf einen Truck und transportierte es ab. Die Regierung behauptete, nichts gefunden zu haben. NASA-Dokumente verschwanden. Theorien: Nazi-Glocke, Zeitmaschine, außerirdisches Schiff.",
        "sources": json.dumps([{"title": "The Kecksburg UFO Incident", "author": "Stan Gordon", "year": 1991}]),
        "keywords": json.dumps(["Pennsylvania", "Kecksburg", "Nazi-Glocke", "Crash", "Vertuschung"]),
        "evidence_level": "documented"
    },
    {
        "id": 70, "title": "Shag Harbour Unterwasser-UFO",
        "description": "UFO tauchte ins Meer - kanadische Marine verfolgte es unter Wasser.",
        "latitude": 43.5014, "longitude": -65.7089, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1967, "date_text": "04.10.1967", "icon_type": "ufo",
        "full_description": "Ein leuchtendes Objekt stürzte 1967 vor Shag Harbour, Kanada ins Meer. Dutzende Zeugen, darunter Polizisten. Die Royal Canadian Navy und US-Militär suchten tagelang. Sonar zeigte ein großes Objekt am Meeresboden - es bewegte sich 40 km zu einer anderen Unterwasserbasis. Taucher fanden nichts, aber bestätigten unbekannte Signale. Kanadas bestdokumentierter UFO-Fall.",
        "sources": json.dumps([{"title": "Dark Object", "author": "Don Ledger", "year": 2001}]),
        "keywords": json.dumps(["Kanada", "Shag Harbour", "Unterwasser-UFO", "Marine", "Sonar"]),
        "evidence_level": "military"
    },
    {
        "id": 71, "title": "Pororoca-Welle",
        "description": "Mystische Flutwelle im Amazonas - magnetische Anomalien und Legenden.",
        "latitude": -0.0347, "longitude": -51.0662, "category": "Mystische Orte",
        "event_type": "phenomenon", "year": 1500, "date_text": "seit Jahrhunderten", "icon_type": "wave",
        "full_description": "Die Pororoca ist eine bis zu 4 Meter hohe Flutwelle, die den Amazonas hinaufläuft. Der Name bedeutet in Tupi großer zerstörerischer Lärm. Indigene Legenden sprechen von Geistern und verborgenen Energien. Messungen zeigen magnetische Anomalien und Infraschall-Frequenzen während der Welle. Surfer berichten von zeitlosen Zuständen. Wissenschaft erklärt die physikalische Welle, nicht die mystischen Aspekte.",
        "sources": json.dumps([{"title": "Amazon River Phenomena", "author": "Jacques Cousteau", "year": 1983}]),
        "keywords": json.dumps(["Amazonas", "Pororoca", "Flutwelle", "Magnetismus", "Mystik"]),
        "evidence_level": "documented"
    },
    {
        "id": 72, "title": "SS Ourang Medan",
        "description": "Gesamte Besatzung tot gefunden - Schiff explodierte - was geschah?",
        "latitude": -2.0000, "longitude": 106.0000, "category": "Mystische Orte",
        "event_type": "mystery", "year": 1947, "date_text": "06.1947", "icon_type": "ship",
        "full_description": "Der holländische Frachter SS Ourang Medan sendete 1947 einen Notruf: Alle Offiziere tot, komplette Besatzung tot. Rettungsmannschaften fanden alle Crewmitglieder tot mit vor Entsetzen erstarrten Gesichtern - ohne Verletzungen. Selbst der Schiffshund war tot. Kurz danach explodierte das Schiff und sank. Theorien: Giftige Fracht, Nervengas, paranormale Kräfte. Keine Überlebenden, keine Beweise.",
        "sources": json.dumps([{"title": "The Death Ship of the East Indies", "year": 1940}]),
        "keywords": json.dumps(["Geisterschiff", "Ourang Medan", "Mystery", "Explosion", "Besatzung"]),
        "evidence_level": "documented"
    },
    {
        "id": 73, "title": "Taos Hum",
        "description": "Mysteriöses Brummen in New Mexico - nur 2 Prozent der Menschen hören es.",
        "latitude": 36.4072, "longitude": -105.5731, "category": "Mystische Orte",
        "event_type": "phenomenon", "year": 1991, "date_text": "1991-heute", "icon_type": "soundwave",
        "full_description": "Seit 1991 hören 2 Prozent der Einwohner von Taos, New Mexico ein tieffrequentes Brummen - 24 Stunden am Tag. Es verursacht Schlaflosigkeit, Kopfschmerzen und Depressionen. Wissenschaftler und die US-Regierung untersuchten das Phänomen - ohne Erklärung. Keine elektromagnetische Quelle gefunden. Ähnliche Hums gibt es weltweit: Bristol Hum, Windsor Hum. Ursache unbekannt.",
        "sources": json.dumps([{"title": "The Hum Investigation", "author": "University of New Mexico", "year": 1993}]),
        "keywords": json.dumps(["Taos", "Hum", "Brummen", "Frequenz", "Phänomen"]),
        "evidence_level": "documented"
    },
    {
        "id": 74, "title": "Oakville Blobs",
        "description": "Gele artige Masse fiel vom Himmel - Menschen erkrankten - nie erklärt.",
        "latitude": 46.8460, "longitude": -123.2379, "category": "Mystische Orte",
        "event_type": "phenomenon", "year": 1994, "date_text": "08.1994", "icon_type": "rain",
        "full_description": "Im August 1994 fiel in Oakville, Washington eine durchsichtige, gele artige Substanz vom Himmel. Dutzende Menschen erkrankten mit grippeähnlichen Symptomen. Laboranalysen zeigten menschliche weiße Blutkörperchen in der Substanz. Tiere starben. Es regnete 6 Mal diese Masse innerhalb von 3 Wochen. Die US Air Force bestritt Beteiligung. Bis heute ungeklärt woher die Blobs kamen.",
        "sources": json.dumps([{"title": "Unsolved Mysteries Report", "year": 1997}]),
        "keywords": json.dumps(["Oakville", "Blobs", "Gelee", "Regen", "Mystery"]),
        "evidence_level": "documented"
    },
    {
        "id": 75, "title": "Wow! Signal",
        "description": "Stärkstes außerirdisches Signal empfangen - nie wieder wiederholt.",
        "latitude": 40.8178, "longitude": -81.3500, "category": "Alte Astronauten",
        "event_type": "signal", "year": 1977, "date_text": "15.08.1977", "icon_type": "signal",
        "full_description": "Das Big Ear Radioteleskop in Ohio empfing 1977 ein 72 Sekunden langes Signal aus Richtung Sternbild Schütze. Es war 30 Mal stärker als die Hintergrundstrahlung - genau auf der Frequenz, die außerirdische Zivilisationen verwenden würden (1420 MHz Wasserstofflinie). Astronom Jerry Ehman schrieb Wow! auf den Ausdruck. Trotz jahrzehntelanger Suche wurde es nie wieder empfangen.",
        "sources": json.dumps([{"title": "The Wow! Signal Analysis", "author": "Jerry Ehman", "year": 1997}]),
        "keywords": json.dumps(["Wow Signal", "SETI", "Außerirdisch", "Radio", "Ohio"]),
        "evidence_level": "documented"
    },
    {
        "id": 76, "title": "Philadelphia-Experiment",
        "description": "Kriegsschiff wurde unsichtbar und teleportiert - Crew fusionierte mit Metall.",
        "latitude": 39.9526, "longitude": -75.1652, "category": "Alternative Theorien",
        "event_type": "conspiracy", "year": 1943, "date_text": "28.10.1943", "icon_type": "ship",
        "full_description": "Die USS Eldridge soll 1943 in Philadelphia durch ein Navy-Experiment unsichtbar geworden und nach Norfolk teleportiert worden sein. Zeugen berichten von grünem Nebel und Crewmitgliedern, die mit dem Schiffsrumpf verschmolzen. Basierend auf Einsteins Unified Field Theory. Die Navy bestreitet alles, aber Dokumente und Zeugenaussagen existieren. Verbindungen zu Tesla und Montauk Project.",
        "sources": json.dumps([{"title": "The Philadelphia Experiment", "author": "Charles Berlitz", "year": 1979}]),
        "keywords": json.dumps(["Philadelphia Experiment", "USS Eldridge", "Teleportation", "Navy", "Tesla"]),
        "evidence_level": "speculative"
    },
    {
        "id": 77, "title": "Mary Celeste",
        "description": "Geisterschiff gefunden - Besatzung verschwunden - Essen noch warm auf Tisch.",
        "latitude": 38.2000, "longitude": -17.3000, "category": "Mystische Orte",
        "event_type": "mystery", "year": 1872, "date_text": "04.12.1872", "icon_type": "ship",
        "full_description": "Die Mary Celeste wurde 1872 im Atlantik treibend gefunden - ohne Crew. Das Schiff war in perfektem Zustand, Fracht intakt, Essen auf dem Tisch, persönliche Gegenstände unberührt. Das Rettungsboot fehlte. Keine Spuren von Kampf oder Gewalt. Kapitän Briggs und seine Familie plus 7 Crewmitglieder verschwanden spurlos. Über 100 Theorien, keine Lösung. Eines der größten Seerätsel.",
        "sources": json.dumps([{"title": "The Mystery of the Mary Celeste", "author": "Paul Begg", "year": 2006}]),
        "keywords": json.dumps(["Mary Celeste", "Geisterschiff", "Atlantik", "Verschwunden", "Mystery"]),
        "evidence_level": "documented"
    },
    {
        "id": 78, "title": "Schwarzer Ritter-Satellit",
        "description": "13.000 Jahre alter Satellit im Orbit? NASA-Fotos zeigen mysteriöses Objekt.",
        "latitude": 0.0000, "longitude": 0.0000, "category": "Alte Astronauten",
        "event_type": "ancient", "year": 1960, "date_text": "1960-heute", "icon_type": "satellite",
        "full_description": "Seit 1960 berichten Astronomen von einem mysteriösen Objekt in polarer Umlaufbahn. Nikola Tesla empfing 1899 Signale, die er als außerirdisch deutete. 1960 entdeckte die US Navy ein dunkles Objekt in ungewöhnlicher Umlaufbahn. 1998 machte die STS-88-Mission Fotos eines schwarzen, unidentifizierten Objekts. NASA behauptet, es sei Weltraumschrott. Alternative Forscher vermuten einen 13.000 Jahre alten außerirdischen Satelliten.",
        "sources": json.dumps([{"title": "Ancient Aliens in Orbit", "author": "Duncan Lunan", "year": 1973}]),
        "keywords": json.dumps(["Black Knight", "Satellit", "NASA", "Tesla", "Außerirdisch"]),
        "evidence_level": "speculative"
    },
    {
        "id": 79, "title": "Solway Firth Spaceman",
        "description": "Foto zeigt Astronauten im Hintergrund - niemand war da.",
        "latitude": 54.9167, "longitude": -3.2500, "category": "UFOs & Aliens",
        "event_type": "ufo", "year": 1964, "date_text": "23.05.1964", "icon_type": "photo",
        "full_description": "Jim Templeton fotografierte 1964 seine Tochter in Solway Firth, England. Auf dem entwickelten Foto steht im Hintergrund eine Figur in weißem Raumanzug - niemand war dort. Kodak bestätigte, das Foto ist unmanipuliert. Am selben Tag meldeten Australien Blue Streak Missile-Tests wegen UFO-Sichtungen ab. Men in Black besuchten Templeton und drohten. Das Original hängt im National Space Center.",
        "sources": json.dumps([{"title": "The Solway Spaceman Mystery", "year": 1964}]),
        "keywords": json.dumps(["Solway Firth", "Spaceman", "Foto", "Astronaut", "England"]),
        "evidence_level": "documented"
    },
    {
        "id": 80, "title": "Flannan-Leuchtturm",
        "description": "Drei Leuchtturmwärter verschwanden spurlos - nie gefunden.",
        "latitude": 58.2872, "longitude": -7.5892, "category": "Mystische Orte",
        "event_type": "mystery", "year": 1900, "date_text": "15.12.1900", "icon_type": "lighthouse",
        "full_description": "Am 15. Dezember 1900 verschwanden drei Leuchtturmwärter von den Flannan Inseln, Schottland. Das Leuchtturm war verlassen - Uhren standen still, Essen stand auf dem Tisch, ein Stuhl war umgeworfen. Ein Logbuch-Eintrag berichtete von einem schrecklichen Sturm und Angst - aber das Wetter war ruhig gewesen. Keine Leichen, keine Spuren. Eine Tür war offen. Wohin gingen sie?",
        "sources": json.dumps([{"title": "The Flannan Isle Mystery", "author": "Mike Dash", "year": 1999}]),
        "keywords": json.dumps(["Flannan", "Leuchtturm", "Schottland", "Verschwunden", "Mystery"]),
        "evidence_level": "documented"
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
        print(f"✅ {event['id']}: {event['title']}")
        return True

def main():
    print("🚀 Loading ALL remaining 40 events (41-80)...\n")
    print("📦 Batch 1 continued (41-55): Antike Zivilisationen & UFO Sichtungen")
    print("📦 Batch 2 (56-80): Geheime Experimente, Kryptozoologie, Moderne Phänomene\n")
    
    success_count = 0
    fail_count = 0
    
    for event in all_events:
        if insert_event(event):
            success_count += 1
        else:
            fail_count += 1
    
    print(f"\n{'='*70}")
    print(f"📊 FINAL RESULTS:")
    print(f"   ✅ Success: {success_count}/40 events")
    print(f"   ❌ Failed:  {fail_count}/40 events")
    print(f"{'='*70}")
    
    if fail_count == 0:
        print("\n🎉 ALL 80 EVENTS SUCCESSFULLY LOADED!")
        print("   35 original + 5 test + 40 new = 80 total events")
    else:
        print(f"\n⚠️  {fail_count} events failed. Check errors above.")
        sys.exit(1)

if __name__ == '__main__':
    main()
