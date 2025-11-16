-- Seed data for events (Map markers with real coordinates)
INSERT OR IGNORE INTO events (id, title, description, latitude, longitude, category, event_type, year, date_text, icon_type, related_document_id) VALUES 

-- Ancient Mysteries
(1, 'Die Große Pyramide von Gizeh', 'Mysteriöse Bauweise mit präzisen astronomischen Ausrichtungen. Angeblich Energiegenerator oder Kommunikationsgerät zu den Sternen.', 29.9792, 31.1342, 'Alte Zivilisationen', 'ancient', -2560, '2560 v.Chr.', 'pyramid', 2),

(2, 'Atlantis (vermutete Lage)', 'Platons legendäre versunkene Insel-Zivilisation. Verschiedene Theorien platzieren sie hier bei den Azoren.', 37.7412, -25.6756, 'Alte Zivilisationen', 'ancient', -9600, '9600 v.Chr.', 'atlantis', 2),

(3, 'Stonehenge', 'Prähistorisches Monument mit unbekanntem Zweck. Astronomisches Observatorium oder Kultstätte?', 51.1789, -1.8262, 'Alte Zivilisationen', 'ancient', -3000, '3000 v.Chr.', 'stone', NULL),

(4, 'Nazca-Linien', 'Riesige Geoglyphen in der Wüste Perus, nur aus der Luft erkennbar. Botschaften an die Götter?', -14.7390, -75.1300, 'Alte Astronauten', 'ancient', -500, '500 v.Chr. - 500 n.Chr.', 'lines', 4),

(5, 'Angkor Wat', 'Gigantische Tempelanlage mit mysteriösen Symbolen und astronomischen Ausrichtungen.', 13.4125, 103.8670, 'Alte Zivilisationen', 'ancient', 1113, '12. Jahrhundert', 'temple', NULL),

(6, 'Moai-Statuen der Osterinsel', 'Hunderte riesige Steinköpfe auf isolierter Insel. Wie wurden sie transportiert und warum?', -27.1127, -109.3497, 'Alte Zivilisationen', 'ancient', 1250, '1250-1500', 'moai', NULL),

(7, 'Göbekli Tepe', 'Älteste bekannte Tempelanlage der Welt - älter als Stonehenge. Revolutioniert Verständnis der Vorgeschichte.', 37.2233, 38.9225, 'Alte Zivilisationen', 'ancient', -9500, '9500 v.Chr.', 'temple', NULL),

(8, 'Puma Punku', 'Präzise geschnittene Steinblöcke in den Anden. Technologie, die unsere übertrifft?', -16.5578, -68.6778, 'Alte Astronauten', 'ancient', 536, '536 n.Chr.', 'stones', 4),

-- UFO & Aliens
(9, 'Area 51', 'Geheime Militärbasis in Nevada. Angeblich werden hier UFOs und außerirdische Technologie erforscht.', 37.2431, -115.7930, 'UFOs', 'ufo', 1955, '1955-heute', 'ufo', 17),

(10, 'Roswell UFO-Absturz', 'Berühmter angeblicher UFO-Absturz 1947. Militär behauptet, es war ein Wetterballon.', 33.3943, -104.5230, 'UFOs', 'ufo', 1947, '2. Juli 1947', 'crash', 17),

(11, 'Rendlesham Forest Incident', 'Britains Roswell - UFO-Sichtungen nahe RAF-Basis durch Militärpersonal dokumentiert.', 52.0943, 1.4507, 'UFOs', 'ufo', 1980, '26.-28. Dez 1980', 'ufo', NULL),

(12, 'Phoenix Lights', 'Tausende sahen riesiges V-förmiges Objekt über Arizona schweben. Nie erklärt.', 33.4484, -112.0740, 'UFOs', 'ufo', 1997, '13. März 1997', 'lights', NULL),

(13, 'Tunguska-Ereignis', 'Mysteriöse Explosion in Sibirien mit der Kraft von 1000 Hiroshima-Bomben. UFO oder Komet?', 60.8858, 101.8936, 'UFOs', 'ufo', 1908, '30. Juni 1908', 'explosion', NULL),

-- Geheimgesellschaften
(14, 'Bohemian Grove', 'Geheimer Elite-Club in Kalifornien. Wo die Mächtigen der Welt im Wald okkulte Rituale abhalten.', 38.4527, -123.0152, 'Geheimgesellschaften', 'conspiracy', 1872, '1872-heute', 'cult', 1),

(15, 'Denver Airport', 'Flughafen mit bizarren Wandgemälden und unterirdischen Tunneln. Illuminati-Hauptquartier?', 39.8561, -104.6737, 'Verschwörungen', 'conspiracy', 1995, '1995', 'airport', NULL),

(16, 'Pentagon', 'Zentrum der US-Militärmacht. Viele Verschwörungstheorien um 9/11 und geheime Programme.', 38.8719, -77.0563, 'Verschwörungen', 'conspiracy', 1943, '1943-heute', 'building', NULL),

(17, 'Vatikan', 'Zentrum der katholischen Kirche. Geheimarchive mit verbotenem Wissen?', 41.9029, 12.4534, 'Geheimgesellschaften', 'mystery', 1929, '1929-heute', 'church', NULL),

(18, 'Skull & Bones Hauptquartier', 'Elite-Geheimbund an der Yale University. Viele US-Präsidenten waren Mitglieder.', 41.3108, -72.9262, 'Geheimgesellschaften', 'conspiracy', 1832, '1832-heute', 'skull', 14),

-- Geheimdienste & Experimente
(19, 'Montauk Air Force Station', 'Angeblicher Ort von geheimen Zeitreise- und Bewusstseinskontroll-Experimenten.', 41.0718, -71.9359, 'Zeitreisen', 'conspiracy', 1971, '1971-1983', 'station', 13),

(20, 'Camp Hero', 'Militärbasis auf Long Island. Schauplatz des Montauk-Projekts.', 41.0617, -71.8621, 'Zeitreisen', 'conspiracy', 1942, '1942-1981', 'radar', 13),

(21, 'Philadelphia Naval Shipyard', 'Ort des legendären Philadelphia-Experiments - angebliche Teleportation eines Kriegsschiffs 1943.', 39.8833, -75.1778, 'Zeitreisen', 'conspiracy', 1943, '28. Okt 1943', 'ship', 10),

(22, 'Langley CIA Hauptquartier', 'Zentrale der CIA in Virginia. Heimat von MK-Ultra und anderen Mind-Control-Programmen.', 38.9516, -77.1467, 'Geheimdienste', 'conspiracy', 1961, '1961-heute', 'cia', 9),

(23, 'Dugway Proving Ground', 'Geheime Militärbasis in Utah. Chemie- und Bio-Waffen-Tests. Chemtrail-Ursprung?', 40.1937, -112.9383, 'Klimamanipulation', 'conspiracy', 1942, '1942-heute', 'chemical', 11),

-- Hohle Erde & Unterirdische Basen
(24, 'Mount Shasta', 'Heiliger Berg mit angeblichen Eingängen zur hohlen Erde und Lemurian-Zivilisation.', 41.4092, -122.1949, 'Hohle Erde', 'mystery', NULL, 'Zeitlos', 'mountain', 8),

(25, 'Nordpol', 'Admiral Byrd berichtete von Eingang zu Agartha, der inneren Erde-Zivilisation.', 90.0000, 0.0000, 'Hohle Erde', 'mystery', 1947, 'Februar 1947', 'pole', 8),

(26, 'Dulce Base', 'Angebliche unterirdische Alien-Basis in New Mexico. Joint-Venture mit Grauen?', 36.9395, -107.0006, 'UFOs', 'conspiracy', NULL, '1970er-heute', 'underground', NULL),

-- Mystische Orte
(27, 'Bermuda-Dreieck', 'Berüchtigtes Gebiet mit unerklärlichen Schiffs- und Flugzeug-Verschwinden.', 25.0000, -71.0000, 'Paralleluniversen', 'mystery', NULL, 'Zeitlos', 'triangle', 20),

(28, 'Sedona Vortex', 'Kraftort mit angeblich starken energetischen Wirbeln und UFO-Sichtungen.', 34.8697, -111.7610, 'Mystik', 'mystery', NULL, 'Zeitlos', 'vortex', 3),

(29, 'Tiahuanaco', 'Prä-Inka-Ruinen in Bolivien. Astronomisch präzise mit mysteriösen Steinarbeiten.', -16.5547, -68.6739, 'Alte Zivilisationen', 'ancient', -200, '200 v.Chr.', 'ruins', NULL),

(30, 'Chichen Itza', 'Maya-Pyramide mit präziser Sonnenwende-Ausrichtung. Wissen der Sterne?', 20.6843, -88.5678, 'Alte Zivilisationen', 'ancient', 600, '600-900 n.Chr.', 'pyramid', NULL),

-- Moderne Verschwörungen
(31, 'CERN Teilchenbeschleuniger', 'Größter Teilchenbeschleuniger der Welt. Öffnet er Portale zu anderen Dimensionen?', 46.2339, 6.0525, 'Paralleluniversen', 'conspiracy', 1954, '1954-heute', 'cern', 20),

(32, 'HAARP Anlage Alaska', 'Hochfrequenz-Forschung oder Wettermanipulations-Waffe?', 62.3900, -145.1500, 'Klimamanipulation', 'conspiracy', 1993, '1993-2014', 'antenna', 11),

(33, 'Bielefeld', 'Die Stadt die nicht existiert - Deutschlands bekannteste Verschwörungstheorie.', 52.0302, 8.5325, 'Verschwörungen', 'conspiracy', NULL, 'Existiert nicht', 'question', NULL),

(34, 'Untersberg', 'Mystischer Berg in den Alpen. Zeitanomalien und Eingänge zu anderen Welten?', 47.7130, 12.9670, 'Paralleluniversen', 'mystery', NULL, 'Zeitlos', 'mountain', NULL),

(35, 'Hessdalen-Lichtphänomen', 'Unerklärliche Lichterscheinungen in norwegischem Tal. Seit Jahrzehnten beobachtet.', 62.8000, 11.2000, 'UFOs', 'mystery', 1981, '1981-heute', 'lights', NULL);
