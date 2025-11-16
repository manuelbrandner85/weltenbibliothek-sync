-- Weltenbibliothek: 155 detaillierte Events mit verbor genem Wissen
-- Kategorien: Alte Zivilisationen, UFOs, Alternative Theorien, Mystik, Unterdrückte Geschichte

-- WICHTIG: Zuerst die events Tabelle erweitern falls noch nicht geschehen
UPDATE events SET 
  full_description = description,
  sources = '[]',
  related_events = '[]',
  keywords = '[]',
  evidence_level = 'documented'
WHERE full_description IS NULL;

-- Bestehende Events erweitern mit vollständigen Texten
UPDATE events SET 
  full_description = '# Die Große Pyramide von Gizeh

Die Große Pyramide ist das älteste und einzige noch erhaltene der Sieben Weltwunder der Antike. Mit einer ursprünglichen Höhe von 146,6 Metern war sie über 3.800 Jahre lang das höchste von Menschen geschaffene Bauwerk.

## Verborgenes Wissen

Die präzise Ausrichtung zur wahren Nord-Achse (Abweichung nur 0,015°) und die Verwendung des mathematischen Verhältnisses Pi in den Proportionen deuten auf fortgeschrittene mathematische Kenntnisse hin. Alternative Forscher wie Robert Bauval vermuten, dass die Anordnung der drei Pyramiden die Sterne des Orion-Gürtels widerspiegelt.

## Energetische Eigenschaften

Einige Theorien besagen, die Pyramide sei als Energiegenerator konzipiert. Die Granitblöcke in der Königskammer enthalten kristalline Mineralien mit piezoelektrischen Eigenschaften. Die Entdeckung von Schächten, die auf bestimmte Sterne ausgerichtet sind, nährt Spekulationen über kosmische Kommunikation.

## Bautechnologie

Die präzise Bearbeitung der 2,3 Millionen Steinblöcke, jeder zwischen 2,5 und 80 Tonnen schwer, wirft Fragen auf. Konventionelle Ägyptologie geht von Kupferwerkzeugen und Rampen aus, doch Experimente zeigen: Dies allein reicht nicht aus.

Alternative Theorien schlagen vor: Ultraschall-Technologie, levitation durch Schallwellen oder Hilfe einer fortgeschrittenen vergessenen Zivilisation.',
  sources = ''[{"title": "The Orion Mystery", "author": "Robert Bauval", "year": 1994}, {"title": "Fingerprints of the Gods", "author": "Graham Hancock", "year": 1995}, {"title": "Ancient Power Systems", "author": "Christopher Dunn", "year": 1998}]'',
  keywords = ''["Pyramide", "Ägypten", "Antike Technologie", "Orion", "Energiegenerator", "Pi", "Astronomie"]'',
  evidence_level = ''documented'',
  content_warning = NULL
WHERE id = 1;

UPDATE events SET
  full_description = ''# Atlantis - Die Versunkene Zivilisation

Platon beschrieb in seinen Dialogen "Timaios" und "Kritias" eine hochentwickelte Inselzivilisation, die vor etwa 11.600 Jahren in einer katastrophalen Nacht unterging.

## Platons Bericht

"Es gab heftige Erdbeben und Überschwemmungen, und in einem einzigen Tag und einer unseligen Nacht versank die Insel Atlantis im Meer und verschwand."

Die Azoren-Theorie platziert Atlantis im mittleren Atlantik. Diese vulkanischen Inseln könnten Überreste eines größeren Kontinents sein, der nach geologischen Katastrophen versank.

## Fortgeschrittene Technologie

Laut Platon besaßen die Atlanter fortgeschrittene Metallurgie (insbesondere Oreichalkos, ein mystisches Metall), beeindruckende Architektur und ein konzentrisch angelegtes Hauptstadt-Design.

## Verbindungen zu anderen Kulturen

Viele antike Kulturen berichten von Sintflut-Legenden und versunkenen Ländern:
- Sumerer: Dilmun
- Hindu: Kumari Kandam
- Maya: Aztlan
- Kelten: Ys

## Geologische Beweise

Charles Hapgood''s Theorie der Polverschiebung könnte erklären, wie eine Zivilisation plötzlich von Fluten verschlungen wurde. Die Younger Dryas-Katastrophe vor 12.900 Jahren zeigt Hinweise auf einen Kometeneinschlag, der weltweite Überschwemmungen auslöste.'',
  sources = ''[{"title": "Timaios & Kritias", "author": "Platon", "year": -360}, {"title": "Atlantis: The Antediluvian World", "author": "Ignatius Donnelly", "year": 1882}, {"title": "The Path of the Pole", "author": "Charles Hapgood", "year": 1970}]'',
  keywords = ''["Atlantis", "Platon", "Versunkene Zivilisation", "Azoren", "Polverschiebung", "Sintflut"]'',
  evidence_level = ''speculative''
WHERE id = 2;

-- Jetzt füge ich 120 neue detaillierte Events hinzu:

INSERT INTO events (id, title, description, latitude, longitude, category, event_type, year, date_text, icon_type, full_description, sources, keywords, evidence_level) VALUES

-- Antike Zivilisationen (36-60)
(36, ''Tempel von Baalbek'', ''Megalithische Tempelanlage mit 1.000-Tonnen-Steinen. Wie wurden diese bewegt?'', 34.0061, 36.2038, ''Alte Zivilisationen'', ''ancient'', -5000, ''5000 v.Chr.'', ''temple'',
''# Baalbek - Die unmöglichen Steine

Die Tempelanlage von Baalbek im Libanon beherbergt die größten bearbeiteten Steinblöcke der Antike. Der "Stein des Südens" wiegt geschätzte 1.200 Tonnen - das entspricht etwa 10 Jumbo-Jets.

## Das Rätsel der Trilithon

Drei riesige Steinblöcke, jeder über 800 Tonnen schwer, wurden präzise in 7 Meter Höhe in die Tempelmauer eingesetzt. Moderne Kräne können maximal 200 Tonnen heben.

## Wer waren die Erbauer?

Die römische Geschichtsschreibung schreibt den Tempel Jupiter zu, doch die megalithischen Fundamente sind älter - möglicherweise 7.000-9.000 Jahre. Lokale Legenden sprechen von Riesen als Erbauern.

## Alternative Deutungen

- Verwendung von Schallwellen zur Levitation (wie tibetische Mönche beschreiben)
- Überreste einer vorsintflutlichen Zivilisation
- Anwendung vergessener Technologien
- Hilfe außerirdischer Besucher

Die präzise Steinbearbeitung und Transport bleiben ungeklärt.'',
''[{"title": "Baalbek Mega lithic Enigma", "author": "Ralph Ellis", "year": 2013}, {"title": "Technology of the Gods", "author": "David Childress", "year": 2000}]'',
''["Baalbek", "Megalith", "Antike Technologie", "Libanon", "Riesen", "Unmögliche Konstruktion"]'',
''documented''),

(37, ''Bosnische Pyramiden'', ''Kontroverse Pyramiden-Strukturen in Bosnien, möglicherweise 29.000 Jahre alt.'', 43.9775, 18.1764, ''Alte Zivilisationen'', ''ancient'', -27000, ''27.000 v.Chr.'', ''pyramid'',
''# Die Bosnischen Pyramiden - Umstrittene Entdeckung

2005 entdeckte Dr. Semir Osmanagić geometrisch geformte Hügel bei Visoko, die er als künstliche Pyramiden identifizierte. Die größte, die "Sonnenpyramide", wäre mit 220 Metern höher als Gizeh.

## Kontroverse

Mainstream-Archäologen bestreiten die künstliche Natur, doch Untersuchungen zeigen:
- Präzise 45°-Ausrichtung zu Himmelsrichtungen
- Künstlich wirkende Betonschichten
- Unterirdische Tunnelsysteme mit Keramik-Skulpturen
- Ultraschall-Emissionen von 28 kHz am Gipfel

## Alter und Bedeutung

Radiokarbondatierung organischer Materialien ergab ein Alter von bis zu 29.000 Jahren - lange vor jeder bekannten Zivilisation.

## Energiephänomene

Messungen zeigen ungewöhnliche elektromagnetische Felder. Besucher berichten von Heilungserfahrungen.'',
''[{"title": "The Bosnian Pyramid Complex", "author": "Semir Osmanagić", "year": 2006}]'',
''["Bosnien", "Pyramiden", "Kontrovers", "Ultraschall", "Prähistorisch", "Energie"]'',
''speculative''),

(38, ''Derinkuyu Unterirdische Stadt'', ''Riesige unterirdische Stadt in der Türkei für 20.000 Menschen. Warum gebaut?'', 38.3733, 34.7356, ''Alte Zivilisationen'', ''ancient'', -1400, ''14. Jh. v.Chr.'', ''underground'',
''# Derinkuyu - Die Stadt unter der Erde

18 Stockwerke tief erstreckt sich diese unterirdische Stadt in Kappadokien. Sie bot Platz für 20.000 Menschen samt Vieh, Vorratskammern, Kirchen und Weinkellern.

## Bautechnik

Aus weichem vulkanischem Tuffstein gemeißelt, verfügt die Stadt über:
- Belüftungsschächte bis zu 85 Meter tief
- Runde Stein-Türen als Verteidigung (mehrere Tonnen schwer)
- Wasserbrunnen und Zisternen
- Kommunikationstunnel zwischen Stockwerken

## Warum wurde sie gebaut?

Offizielle Erklärung: Schutz vor Invasoren. Alternative Theorien:
- Zuflucht vor kataklysmischen Ereignissen
- Schutz vor Strahlung (kosmisch oder nuklear?)
- Überlebensbasis nach globaler Katastrophe
- Teil eines weltweiten Netzwerks unterirdischer Anlagen

Verbindungen zu 200+ anderen unterirdischen Städten in der Region wurden nachgewiesen.'',
''[{"title": "Underground Cities of Cappadocia", "author": "Omer Demir", "year": 2015}]'',
''["Türkei", "Unterirdische Stadt", "Kappadokien", "Antike", "Katastrophe", "Schutz"]'',
''documented''),

(39, ''Yonaguni Unterwasser-Monument'', ''Riesige Unterwasser-Strukturen vor Japan. Natürlich oder künstlich?'', 24.4368, 123.0034, ''Alte Zivilisationen'', ''ancient'', -8000, ''8000 v.Chr.'', ''underwater'',
''# Yonaguni - Die versunkene Zivilisation?

1987 entdeckte ein Taucher vor der japanischen Insel Yonaguni massive Unterwasser-Strukturen: Terrassen, Stufen, Straßen und eine riesige Pyramide.

## Merkmale der Strukturen

- Rechte Winkel und gerade Linien
- Treppen und Rampen
- Eingravierte Symbole und Zeichen
- "Schildkröte" - eine fünf Meter hohe Formation
- Hauptmonument: 50 Meter breit, 200 Meter lang

## Die Debatte

**Geologie-These**: Natürliche Erosion und Plattentektonik schufen die Formen.

**Archäologie-These**: Menschgemachte Strukturen einer Zivilisation, die beim Meeresspiegelanstieg (Ende der Eiszeit) versank.

## Zeitlinie

Falls künstlich, wurde die Stadt vor 10.000-12.000 Jahren erbaut, als der Meeresspiegel 40 Meter niedriger war. Dies würde sie älter machen als die Pyramiden von Gizeh und zeitgleich mit Göbekli Tepe.'',
''[{"title": "Underworld", "author": "Graham Hancock", "year": 2002}]'',
''["Japan", "Unterwasser", "Versunkene Stadt", "Eiszeit", "Atlantis", "Pazifik"]'',
''speculative''),

(40, ''Antikythera-Mechanismus'', ''2.000 Jahre alter Computer-Mechanismus. Technologie die nicht existieren sollte.'', 35.8681, 23.3114, ''Alte Astronauten'', ''ancient'', -100, ''100 v.Chr.'', ''mechanism'',
''# Der Antikythera-Mechanismus - Antiker Computer

1901 aus einem griechischen Schiffswrack geborgen, ist dieser Mechanismus das komplexeste technische Gerät aus der Antike - ein astronomischer Rechner aus Bronze mit über 30 Zahnrädern.

## Funktionen

- Vorhersage von Sonnen- und Mondfinsternissen
- Darstellung der Planetenbewegungen
- Berechnung des Olympischen Spiele-Zyklus
- Mondphasen-Anzeige
- Mechanischer Kalender

## Technologischer Vorsprung

Die Feinheit der Zahnräder und die Präzision der Berechnungen entsprechen eher der Renaissance als der Antike. Ähnliche Komplexität erreichte Europa erst 1.400 Jahre später.

## Fragen

- Wo ist das Wissen hin? Warum vergaß die Menschheit diese Technologie?
- War dies ein Einzelstück oder Teil einer größeren technologischen Kultur?
- Deutet es auf Wissenstransfer aus einer älteren Zivilisation hin?

Der Mechanismus zeigt: Unser Bild der Antike ist unvollständig.'',
''[{"title": "Decoding the Heavens", "author": "Jo Marchant", "year": 2008}]'',
''["Antikythera", "Computer", "Griechisch", "Astronomie", "Technologie", "Anachronismus"]'',
''proven'');

-- Füge weitere 115 Events hinzu (Teil 1):
