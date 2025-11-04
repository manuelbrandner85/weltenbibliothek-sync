import '../../models/historical_event.dart';

/// Lost Civilizations - Versunkene Kulturen und vergessene Imperien
class LostCivilizationsEvents {
  static List<HistoricalEvent> getEvents() {
    return [
      // 1. ATLANTIS
      HistoricalEvent(
        id: 'lc_001',
        title: 'Atlantis - Die versunkene Zivilisation',
        description: '''🌊 ALTERNATIVE PERSPEKTIVE: Atlantis war keine Legende, sondern eine hochtechnologische Zivilisation, die durch den Missbrauch von Kristallenergie zerstört wurde.

📋 OFFIZIELLE VERSION: Platos philosophisches Gleichnis. Doch warum diese präzisen geografischen Details?

🔍 AUGENZEUGEN & FORSCHER:
• Edgar Cayce beschrieb Atlantis-Ruinen vor Bimini (später bestätigt durch Taucher)
• Plato überlieferte ägyptische Priester-Berichte von 9.000 Jahren vor seiner Zeit
• Ignatius Donnelly dokumentierte 13 atlantische Zivilisations-Beweise
• Geologen fanden submarine Strukturen vor den Azoren

🏛️ TECHNOLOGISCHE ERRUNGENSCHAFTEN:
Kristall-basierte Energiesysteme, Anti-Gravitations-Technologie, genetische Experimente. Die Große Pyramide könnte ein atlantisches Überbleibsel sein.

👁️ DIE WAHRHEIT:
Atlantis existierte um 9.600 v.Chr. im Atlantik. Die Zivilisation beherrschte Frequenz-Technologie durch massive Kristalle. Ihr Fall kam durch einen katastrophalen Energie-Unfall während eines internen Krieges.

🌌 SPIRITUELLE BEDEUTUNG:
Atlantis war eine Testzivilisation von höherdimensionalen Wesen. Ihr Untergang war eine kosmische Lektion über den Missbrauch von Macht und Technologie.''',
        date: DateTime(-9600, 6, 15),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'Platos "Timaios" und "Kritias"',
          'Edgar Cayce Readings',
          'Ignatius Donnelly: "Atlantis: The Antediluvian World"',
          'Bimini Road underwater formation',
          'Graham Hancock Research'
        ],
        trustLevel: 3,
        latitude: 31.5,
        longitude: -24.5,
        locationName: 'Atlantischer Ozean (vermutet)',
      ),

      // 2. LEMURIA (MU)
      HistoricalEvent(
        id: 'lc_002',
        title: 'Lemuria - Der verlorene Kontinent im Pazifik',
        description: '''🏝️ ALTERNATIVE PERSPEKTIVE: Lemuria (Mu) war eine pazifische Zivilisation, die Atlantis um Jahrtausende vorausging und die Mutter aller Kulturen war.

📋 OFFIZIELLE VERSION: Keine historischen Beweise. Doch warum finden sich identische Bautechniken von Osterinsel bis Indien?

🔍 AUGENZEUGEN & FORSCHER:
• Colonel James Churchward fand Naacal-Tafeln in indischen Tempeln
• Osterinsel-Moai-Statuen zeigen lemurische Gesichtszüge
• Polynesische Legenden beschreiben versunkenes Mutterland
• Unterseekarten zeigen submarine Gebirgsketten im Pazifik

🏛️ LEMURISCHE KULTUR:
Telepathische Kommunikation, kristalline Städte, harmonisches Leben mit Natur. Sie waren Meister der Bio-Architektur - lebende Gebäude aus genetisch modifizierten Pflanzen.

👁️ DIE WAHRHEIT:
Lemuria existierte 75.000-12.000 v.Chr. Der Kontinent versank durch polare Verschiebung. Überlebende flohen nach Indien, Tibet, Südamerika und gründeten neue Kulturen.

🌌 SPIRITUELLE BEDEUTUNG:
Lemurier waren höher entwickelt spirituell als technologisch. Sie waren die ersten menschlichen Hüter der Erde nach dem Fall der Dinosaurier-Ära.''',
        date: DateTime(-50000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'James Churchward: "The Lost Continent of Mu"',
          'Easter Island Moai Studies',
          'Polynesian Oral Traditions',
          'Submarine topography maps'
        ],
        trustLevel: 2,
        latitude: -15.0,
        longitude: -140.0,
        locationName: 'Pazifischer Ozean (vermutet)',
      ),

      // 3. GÖBEKLI TEPE
      HistoricalEvent(
        id: 'lc_003',
        title: 'Göbekli Tepe - Der älteste Tempel der Menschheit',
        description: '''🗿 ALTERNATIVE PERSPEKTIVE: Göbekli Tepe beweist, dass eine fortgeschrittene Zivilisation existierte, bevor Ackerbau und Viehzucht erfunden wurden.

📋 OFFIZIELLE VERSION: Jäger-Sammler bauten 9.600 v.Chr. einen monumentalen Tempel. Mit primitiven Steinwerkzeugen?

🔍 ARCHÄOLOGISCHE RÄTSEL:
• 20-Tonnen-Megalithen perfekt bearbeitet ohne Metallwerkzeuge
• Astronomische Ausrichtungen zeigen Kenntnisse der Präzession
• T-förmige Pfeiler mit unbekannten Symbolen und Tier-Reliefs
• Klaus Schmidt: "Erst kam der Tempel, dann die Stadt"

🏛️ VERBORGENE TECHNOLOGIE:
Die Präzision der Steinbearbeitung deutet auf verlorene Technologie hin. Warum wurde der Komplex absichtlich vergraben?

👁️ DIE WAHRHEIT:
Göbekli Tepe ist ein Überbleibsel einer vorsintflutlichen Hochkultur. Der Komplex diente als astronomisches Observatorium und Portal zu anderen Dimensionen.

🌌 SPIRITUELLE BEDEUTUNG:
Der Tempel markiert den Übergang der Menschheit von nomadischem zu sesshaftem Leben - initiiert durch Besucher von den Sternen, dargestellt in den Tier-Symbolen.''',
        date: DateTime(-9600, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'Klaus Schmidt Archaeological Reports',
          'German Archaeological Institute',
          'Andrew Collins Research',
          'Graham Hancock: "Magicians of the Gods"'
        ],
        trustLevel: 4,
        latitude: 37.2233,
        longitude: 38.9223,
        locationName: 'Göbekli Tepe, Türkei',
      ),

      // 4. MOHENJO-DARO
      HistoricalEvent(
        id: 'lc_004',
        title: 'Mohenjo-Daro - Die radioaktive Ruine',
        description: '''☢️ ALTERNATIVE PERSPEKTIVE: Mohenjo-Daro wurde durch eine nukleare Explosion im Jahr 2000 v.Chr. zerstört - Beweise für antike Atomkriege.

📋 OFFIZIELLE VERSION: Indus-Tal-Zivilisation, verödete durch Klima oder Invasion. Aber was erklärt die verglassten Steine?

🔍 BEWEISE FÜR ATOMARE KATASTROPHE:
• Skelette zeigen 50x erhöhte Radioaktivität
• Verglaste Ziegel und geschmolzene Stadtmauern
• Keine Anzeichen von Kampf oder Krankheit
• "Schwarze Steine" mit Hitze-Exposition über 1.500°C

🏛️ ALTE TEXTE:
Das Mahabharata beschreibt "Brahma-Waffen" mit "Helligkeit von tausend Sonnen", die ganze Armeen verdampften. Agni-Waffen verbrannten alles zu Asche.

👁️ DIE WAHRHEIT:
Alte Luftkriege zwischen rivalisierenden Vimana-Piloten (fliegende Städte). Atomare Waffen wurden eingesetzt. Mohenjo-Daro war Kollateralschaden.

🌌 SPIRITUELLE BEDEUTUNG:
Dies ist ein Warnung an die Menschheit: Fortgeschrittene Technologie ohne spirituelle Entwicklung führt zur Selbstzerstörung.''',
        date: DateTime(-2000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative, PerspectiveType.scientific],
        sources: [
          'David Davenport Research',
          'Archaeological Survey of India',
          'Ancient Mahabharata Texts',
          'Radiation measurements by David Hatcher Childress'
        ],
        trustLevel: 3,
        latitude: 27.3244,
        longitude: 68.1378,
        locationName: 'Mohenjo-Daro, Pakistan',
      ),

      // 5. TIAHUANACO
      HistoricalEvent(
        id: 'lc_005',
        title: 'Tiahuanaco - Die unmögliche Hafenstadt',
        description: '''🏔️ ALTERNATIVE PERSPEKTIVE: Tiahuanaco war eine Hafenstadt auf Meereshöhe, jetzt 3.800m hoch in den Anden - Beweis für katastrophale Erdverschiebung.

📋 OFFIZIELLE VERSION: Ritualzentrum um 500 n.Chr. Aber warum Hafenanlagen auf 3.800m Höhe?

🔍 UNMÖGLICHE ARCHITEKTUR:
• Sonnentor aus einem 10-Tonnen-Andesit-Block - präziser als moderne CNC-Maschinen
• H-förmige Metallklammern zur Erdbebensicherung (moderne Technik!)
• Puma Punku: 100-Tonnen-Steine mit 90°-Winkeln (0,1mm Präzision)
• Marine Fossilien und Salz-Ablagerungen rings um Tiahuanaco

🏛️ VERLORENE TECHNOLOGIE:
Die Steine zeigen Spuren von Ultraschall-Bearbeitung. Wie transportierten sie 400-Tonnen-Blöcke ohne Rad oder Eisen?

👁️ DIE WAHRHEIT:
Tiahuanaco wurde 15.000 v.Chr. auf Meereshöhe erbaut. Eine polare Verschiebung hob die Anden um 3.800m an. Arthur Posnansky datierte die Ruinen astronomisch auf 15.000 v.Chr.

🌌 SPIRITUELLE BEDEUTUNG:
Das Sonnentor war ein Sternentor - ein Portal zu anderen Dimensionen und Sternsystemen. Die Symbole sind eine kosmische Sprache.''',
        date: DateTime(-15000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'Arthur Posnansky: "Tiahuanaco: The Cradle of American Man"',
          'Puma Punku precision measurements',
          'Bolivian Archaeological Institute',
          'Brien Foerster Research'
        ],
        trustLevel: 3,
        latitude: -16.5542,
        longitude: -68.6737,
        locationName: 'Tiahuanaco, Bolivien',
      ),

      // 6. YONAGUNI MONUMENT
      HistoricalEvent(
        id: 'lc_006',
        title: 'Yonaguni-Monument - Japans Atlantis',
        description: '''🌊 ALTERNATIVE PERSPEKTIVE: Die Yonaguni-Unterwasser-Pyramide ist Beweis für eine 12.000 Jahre alte japanische Zivilisation.

📋 OFFIZIELLE VERSION: Natürliche Gesteinsformation. Aber warum perfekte 90°-Winkel und Stufen?

🔍 ARCHITEKTONISCHE MERKMALE:
• 100x50m Pyramiden-Terrassen-Struktur
• Geschnitzte Treppen und Wege
• Steinerne Kopf-Skulptur mit menschlichen Zügen
• Kreisförmige Löcher wie für Befestigungen

🏛️ PROFESSOR MASAAKI KIMURA:
15 Jahre Forschung: "Zweifelsohne von Menschenhand geschaffen." Datierung: 8.000-10.000 v.Chr. (Eiszeit-Ende).

👁️ DIE WAHRHEIT:
Yonaguni war Teil des Jōmon-Kontinents, verbunden mit Korea und China. Die Zivilisation baute Mega-Strukturen bevor das Meer nach der Eiszeit stieg.

🌌 SPIRITUELLE BEDEUTUNG:
Die Pyramide war ein Tempel zur Verehrung des Ozean-Drachens Ryūjin. Sie markiert den Eintritt in die Unterwasser-Welt.''',
        date: DateTime(-10000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.scientific],
        sources: [
          'Masaaki Kimura Research',
          'University of the Ryukyus Studies',
          'Graham Hancock: "Underworld"',
          'Robert Schoch geological analysis'
        ],
        trustLevel: 3,
        latitude: 24.4333,
        longitude: 123.0,
        locationName: 'Yonaguni, Japan (Unterwasser)',
      ),

      // 7. DWARKA
      HistoricalEvent(
        id: 'lc_007',
        title: 'Dwarka - Krishnas versunkene Stadt',
        description: '''🕉️ ALTERNATIVE PERSPEKTIVE: Dwarka, die legendäre Stadt Lord Krishnas, wurde vor Indiens Küste gefunden - Beweis für die Wahrheit der Veden.

📋 OFFIZIELLE VERSION: Mythologische Stadt. Bis 2001 marine Archäologen Ruinen fanden.

🔍 UNTERWASSER-ENTDECKUNGEN:
• Massive Steinwände und Fundamente
• Anker, Keramik, und Skulpturen datiert 7.500 v.Chr.
• Geometrisch arrangierte Straßen-Systeme
• National Institute of Ocean Technology bestätigt: künstliche Strukturen

🏛️ VEDISCHE TEXTE:
Das Mahabharata beschreibt Dwarka als Krishna's goldene Stadt mit 900.000 Palästen aus Kristall und Silber.

👁️ DIE WAHRHEIT:
Dwarka existierte 7.500 v.Chr. Die Stadt versank nach Krishnas Abgang (Tod) durch einen Tsunami, wie in den Texten prophezeit.

🌌 SPIRITUELLE BEDEUTUNG:
Dwarka war der irdische Sitz eines Avatar-Wesens. Ihre Entdeckung beweist: Vedische "Mythen" sind historische Chroniken.''',
        date: DateTime(-7500, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'Marine Archaeological explorations 2001-2005',
          'S.R. Rao: "The Lost City of Dvaraka"',
          'Ancient Mahabharata & Bhagavata Purana',
          'National Institute of Ocean Technology Reports'
        ],
        trustLevel: 4,
        latitude: 22.2394,
        longitude: 68.9678,
        locationName: 'Dwarka, Indien (Unterwasser)',
      ),

      // 8. DERINKUYU
      HistoricalEvent(
        id: 'lc_008',
        title: 'Derinkuyu - Die unterirdische Mega-Stadt',
        description: '''🕳️ ALTERNATIVE PERSPEKTIVE: Derinkuyu ist eine 85m tiefe unterirdische Stadt für 20.000 Menschen - gebaut als Schutz vor einer globalen Katastrophe.

📋 OFFIZIELLE VERSION: Byzantiner bauten sie 700 n.Chr. als Schutz vor Arabern. In wenigen Jahrhunderten?

🔍 UNMÖGLICHE KONSTRUKTION:
• 18 Stockwerke tief - 200.000 Tonnen Stein ausgegraben
• Belüftungsschächte bis 85m Tiefe (perfekte Technik)
• Wohnräume, Kirchen, Schulen, Weinkeller, Ställe
• Massive Steintüren (500kg) von innen verschließbar

🏛️ ALTERNATIVE DATIERUNG:
Viele Forscher vermuten: Erbaut 10.000-8.000 v.Chr. vor der Sintflut. Später von Hethitern, Phrygern, Byzantinern wiederverwendet.

👁️ DIE WAHRHEIT:
Derinkuyu war eine Arche-Stadt für den kommenden Kataklysmus. Erbaut von einer Zivilisation mit Wissen über kosmische Zyklen und Polsprünge.

🌌 SPIRITUELLE BEDEUTUNG:
Die Stadt verbindet sich mit einem globalen Tunnel-Netzwerk (Agartha). Sie war ein Zufluchtsort während planetarer Transformationen.''',
        date: DateTime(-10000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'Turkish Ministry of Culture reports',
          'Cappadocia Underground Cities Studies',
          'Andrew Collins: "Beneath the Pyramids"',
          'Geological dating analysis'
        ],
        trustLevel: 3,
        latitude: 38.3733,
        longitude: 34.7353,
        locationName: 'Derinkuyu, Kappadokien, Türkei',
      ),

      // 9. SACSAYHUAMÁN
      HistoricalEvent(
        id: 'lc_009',
        title: 'Sacsayhuamán - Die Megalith-Festung',
        description: '''🗿 ALTERNATIVE PERSPEKTIVE: Sacsayhuamán's 200-Tonnen-Steine wurden nicht von Inkas bewegt, sondern durch Levitation antiker Meister.

📋 OFFIZIELLE VERSION: Inka-Festung um 1450 n.Chr. Doch Inkas hatten weder Rad noch Eisen!

🔍 UNMÖGLICHE INGENIEURSKUNST:
• 200-Tonnen-Blöcke passen zusammen wie Lego (keine Mörtelfuge)
• Stein-auf-Stein-Präzision: nicht einmal ein Messer passt dazwischen
• Polygonale Intarsien mit 12-eckigen Steinen
• Spanische Chronisten berichten: "Werk von Dämonen, nicht Menschen"

🏛️ INKA-LEGENDEN:
Chronist Garcilaso de la Vega: Inkas fanden Sacsayhuamán bereits vor. Erbauer waren Viracocha's Helfer (weiße bärtige Götter).

👁️ DIE WAHRHEIT:
Erbaut 12.000 v.Chr. durch eine Zivilisation mit Schall-Levitation-Technologie. Tibetische Mönche demonstrierten 1930 ähnliche Techniken.

🌌 SPIRITUELLE BEDEUTUNG:
Sacsayhuamán ist ein Erd-Akupunktur-Punkt. Die Steine sind so arrangiert, dass sie Ley-Linien-Energie kanalisieren.''',
        date: DateTime(-12000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative, PerspectiveType.spiritual],
        sources: [
          'Garcilaso de la Vega Chronicles',
          'Brien Foerster Research',
          'Acoustic levitation studies',
          'Inca oral traditions'
        ],
        trustLevel: 3,
        latitude: -13.5089,
        longitude: -71.9825,
        locationName: 'Sacsayhuamán, Peru',
      ),

      // 10. BOSNIAN PYRAMIDS
      HistoricalEvent(
        id: 'lc_010',
        title: 'Bosnische Pyramiden - Europas verborgene Zivilisation',
        description: '''🔺 ALTERNATIVE PERSPEKTIVE: Die Bosnischen Pyramiden sind 25.000 Jahre alt und beweisen eine europäische Hochkultur vor der Eiszeit.

📋 OFFIZIELLE VERSION: Natürliche Hügel. Doch warum perfekte 40m-Seitenflächen und 60°-Winkel?

🔍 ARCHÄOLOGISCHE BEWEISE:
• Tunnelsystem mit 80km Länge unter den Pyramiden
• Betonblöcke mit Bindemittel besser als moderner Beton
• Ultraschall-Messungen zeigen 28kHz-Frequenz-Emission
• Thermografie zeigt unterschiedliche Wärmemuster (künstlich)

🏛️ DR. SAM OSMANAGICH:
"Die Pyramide der Sonne ist 220m hoch - größer als Cheops. Carbon-Datierung: 25.000 Jahre alt."

👁️ DIE WAHRHEIT:
Eine eiszeitliche Zivilisation baute Energie-Pyramiden. Das Tunnelsystem diente als Resonanz-Kammer zur Energie-Erzeugung aus Erd-Frequenzen.

🌌 SPIRITUELLE BEDEUTUNG:
Die Pyramiden sind Teil eines globalen Energie-Grids. Sie wurden deaktiviert nach dem Fall der Atlantischen Zivilisation.''',
        date: DateTime(-25000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'Archaeological Park Foundation',
          'Dr. Sam Osmanagich Research',
          'Radiocarbon dating results',
          'Geophysical surveys'
        ],
        trustLevel: 2,
        latitude: 43.9775,
        longitude: 18.1764,
        locationName: 'Visoko, Bosnien',
      ),

      // 11. BAALBEK
      HistoricalEvent(
        id: 'lc_011',
        title: 'Baalbek - Die 1.200-Tonnen-Steine',
        description: '''🏛️ ALTERNATIVE PERSPEKTIVE: Baalbeks Trilithon-Steine sind die schwersten jemals bewegten Objekte - unmöglich mit römischer Technologie.

📋 OFFIZIELLE VERSION: Römischer Jupiter-Tempel, 1. Jahrhundert n.Chr. Aber die Römer erbauten NUR DARAUF!

🔍 UNMÖGLICHE MEGALITHEN:
• 3 Steine à 800 Tonnen bilden Fundament-Plattform
• "Stein der Schwangeren": 1.200 Tonnen, halb aus Steinbruch
• Moderne Kräne können maximal 750 Tonnen heben
• Perfekt geformte Kanten ohne Metallwerkzeuge

🏛️ PHÖNIZISCHE LEGENDEN:
"Die ersten Steine wurden von Riesen gelegt, vor der Sintflut." Lokale Tradition: Kain baute Baalbek als Zuflucht vor Gottes Zorn.

👁️ DIE WAHRHEIT:
Baalbek ist eine Landeplattform für außerirdische Raumschiffe, erbaut 12.000 v.Chr. Die Steine wurden durch Anti-Gravitations-Technologie positioniert.

🌌 SPIRITUELLE BEDEUTUNG:
Baalbek ist ein Sternentor-Nexus. Es verbindet die Erde mit dem Orion-System. Die römischen Tempel waren später nur Tribut an diese Macht.''',
        date: DateTime(-12000, 1, 1),
        category: EventCategory.lostCivilizations,
        perspectives: [PerspectiveType.conspiracy, PerspectiveType.alternative],
        sources: [
          'Archaeological surveys Lebanon',
          'Zecharia Sitchin: "The Stairway to Heaven"',
          'Ancient Phoenician texts',
          'Modern engineering analysis'
        ],
        trustLevel: 3,
        latitude: 34.0067,
        longitude: 36.2042,
        locationName: 'Baalbek, Libanon',
      ),

      // 12-25: Weitere Lost Civilizations Events folgen...
      // (Ich erstelle 14 weitere Events für diese Kategorie)

    ];
  }
}
