import 'package:latlong2/latlong.dart';

/// Echte Ley-Linien-Verbindungen basierend auf Becker-Hagens Grid
/// und historischer Ley-Linien-Forschung
/// 
/// Quellen:
/// - Becker-Hagens Planetary Grid System
/// - Ivan Sanderson's 12 Vile Vortices
/// - Alfred Watkins Original Ley Lines Research
/// - Sacred Sites Research 2024
class RealLeyLinesData {
  /// Hauptverbindungen zwischen bekannten antiken Stätten
  static List<LeyLineConnection> getMajorConnections() {
    return [
      // 1. GIZEH PYRAMIDEN - STONEHENGE - NAZCA Linie
      LeyLineConnection(
        name: 'Ancient Monuments Alignment',
        points: [
          LatLng(29.9792, 31.1342), // Gizeh Pyramiden
          LatLng(51.1789, -1.8262),  // Stonehenge
          LatLng(-14.7390, -75.1300), // Nazca Lines
        ],
        type: LeyLineType.ancientMonuments,
      ),
      
      // 2. GIZEH - EASTER ISLAND - MACHU PICCHU Verbindung
      LeyLineConnection(
        name: 'Pacific Sacred Triangle',
        points: [
          LatLng(29.9792, 31.1342),   // Gizeh Pyramiden
          LatLng(-27.1127, -109.3497), // Easter Island (Moai)
          LatLng(-13.1631, -72.5450),  // Machu Picchu
        ],
        type: LeyLineType.pacificRing,
      ),
      
      // 3. STONEHENGE - GIZEH - ANGKOR WAT Linie
      LeyLineConnection(
        name: 'Eurasian Energy Belt',
        points: [
          LatLng(51.1789, -1.8262),   // Stonehenge
          LatLng(29.9792, 31.1342),   // Gizeh Pyramiden
          LatLng(13.4125, 103.8670),  // Angkor Wat
        ],
        type: LeyLineType.eurasianBelt,
      ),
      
      // 4. BERMUDA TRIANGLE - GIZEH - MOHENJO-DARO (Sanderson's Vortex Line)
      LeyLineConnection(
        name: 'Sanderson Vortex Chain',
        points: [
          LatLng(25.0, -71.0),        // Bermuda Triangle
          LatLng(29.9792, 31.1342),   // Gizeh Pyramiden
          LatLng(27.3244, 68.1378),   // Mohenjo-Daro
        ],
        type: LeyLineType.vortexChain,
      ),
      
      // 5. STONEHENGE - BAALBEK - GÖBEKLI TEPE
      LeyLineConnection(
        name: 'Ancient Mediterranean Arc',
        points: [
          LatLng(51.1789, -1.8262),   // Stonehenge
          LatLng(34.0067, 36.2042),   // Baalbek
          LatLng(37.2233, 38.9223),   // Göbekli Tepe
        ],
        type: LeyLineType.mediterraneanArc,
      ),
      
      // 6. TEOTIHUACAN - NAZCA - TIAHUANACO (Amerikanische Linie)
      LeyLineConnection(
        name: 'American Sacred Axis',
        points: [
          LatLng(19.6925, -98.8438),  // Teotihuacan (Pyramiden)
          LatLng(-14.7390, -75.1300), // Nazca Lines
          LatLng(-16.5542, -68.6737), // Tiahuanaco
        ],
        type: LeyLineType.americanAxis,
      ),
      
      // 7. EASTER ISLAND - NAZCA - GIZEH (Pazifik-Atlantik Linie)
      LeyLineConnection(
        name: 'Trans-Pacific Connection',
        points: [
          LatLng(-27.1127, -109.3497), // Easter Island
          LatLng(-14.7390, -75.1300),  // Nazca Lines
          LatLng(29.9792, 31.1342),    // Gizeh Pyramiden
        ],
        type: LeyLineType.transPacific,
      ),
      
      // 8. STONEHENGE - RENNES-LE-CHÂTEAU - ROM - DELPHI
      LeyLineConnection(
        name: 'European Mystical Line',
        points: [
          LatLng(51.1789, -1.8262),   // Stonehenge
          LatLng(42.9278, 2.2597),    // Rennes-le-Château
          LatLng(41.9028, 12.4964),   // Rom (Vatikan)
          LatLng(38.4824, 22.5010),   // Delphi
        ],
        type: LeyLineType.europeanMystical,
      ),
      
      // 9. GIZEH - PETRA - JERUSALEM - GÖBEKLI TEPE
      LeyLineConnection(
        name: 'Middle Eastern Sacred Path',
        points: [
          LatLng(29.9792, 31.1342),   // Gizeh Pyramiden
          LatLng(30.3285, 35.4444),   // Petra
          LatLng(31.7683, 35.2137),   // Jerusalem
          LatLng(37.2233, 38.9223),   // Göbekli Tepe
        ],
        type: LeyLineType.middleEastern,
      ),
      
      // 10. ATLANTIS-ACHSE: AZOREN - BIMINI - BERMUDA
      LeyLineConnection(
        name: 'Atlantis Triangle',
        points: [
          LatLng(37.7412, -25.6756),  // Azoren
          LatLng(25.7617, -79.2990),  // Bimini Road
          LatLng(25.0, -71.0),        // Bermuda Triangle
        ],
        type: LeyLineType.atlantisTriangle,
      ),
      
      // 11. ROSWELL - AREA 51 - DULCE BASE (UFO-Dreieck)
      LeyLineConnection(
        name: 'UFO Activity Triangle',
        points: [
          LatLng(33.3942, -104.5230), // Roswell
          LatLng(37.2431, -115.8103), // Area 51
          LatLng(36.9350, -106.9981), // Dulce Base
        ],
        type: LeyLineType.ufoTriangle,
      ),
      
      // 12. SKINWALKER RANCH - SEDONA - CHACO CANYON
      LeyLineConnection(
        name: 'American Vortex Line',
        points: [
          LatLng(40.2586, -109.8853), // Skinwalker Ranch
          LatLng(34.8697, -111.7610), // Sedona
          LatLng(36.0544, -107.9651), // Chaco Canyon
        ],
        type: LeyLineType.americanVortex,
      ),
      
      // 13. GLASTONBURY - AVEBURY - STONEHENGE (Britische Linie)
      LeyLineConnection(
        name: 'British Ley Line',
        points: [
          LatLng(51.1466, -2.7145),   // Glastonbury Tor
          LatLng(51.4291, -1.8536),   // Avebury
          LatLng(51.1789, -1.8262),   // Stonehenge
        ],
        type: LeyLineType.britishLey,
      ),
      
      // 14. ANGKOR WAT - BOROBUDUR - BALI (Asiatische Tempel-Linie)
      LeyLineConnection(
        name: 'Southeast Asian Temple Network',
        points: [
          LatLng(13.4125, 103.8670),  // Angkor Wat
          LatLng(-7.6079, 110.2038),  // Borobudur
          LatLng(-8.5069, 115.2625),  // Bali (Besakih Temple)
        ],
        type: LeyLineType.asianTemples,
      ),
      
      // 15. GIZEH - MEKKA - GREAT ZIMBABWE (Afrika-Linie)
      LeyLineConnection(
        name: 'African Sacred Meridian',
        points: [
          LatLng(29.9792, 31.1342),   // Gizeh Pyramiden
          LatLng(21.4225, 39.8262),   // Mekka
          LatLng(-20.2674, 30.9337),  // Great Zimbabwe
        ],
        type: LeyLineType.africanMeridian,
      ),
    ];
  }
  
  /// Sandersons 12 Vile Vortices (Becker-Hagens Grid Punkte)
  static List<LeyLineConnection> getVortexConnections() {
    final vortexPoints = [
      LatLng(90.0, 0.0),              // 1. Nordpol
      LatLng(-90.0, 0.0),             // 2. Südpol
      LatLng(25.0, -71.0),            // 3. Bermuda Triangle
      LatLng(-27.1127, -109.3497),    // 4. Easter Island
      LatLng(30.0, 105.0),            // 5. Devil's Sea (Japan)
      LatLng(10.0, -20.0),            // 6. Algerien Megaliths
      LatLng(-30.0, 25.0),            // 7. South Atlantic Anomaly
      LatLng(-20.2674, 30.9337),      // 8. Great Zimbabwe
      LatLng(27.3244, 68.1378),       // 9. Mohenjo-Daro
      LatLng(20.0, -157.0),           // 10. Hawaii
      LatLng(-15.0, 165.0),           // 11. New Hebrides Trench
      LatLng(-10.0, 95.0),            // 12. Wharton Basin
    ];
    
    // Verbinde Vortex-Punkte im Grid
    final connections = <LeyLineConnection>[];
    
    // Pentagon-Verbindungen zwischen den Vortices
    connections.add(LeyLineConnection(
      name: 'Vortex Ring 1',
      points: [
        vortexPoints[2], // Bermuda
        vortexPoints[3], // Easter Island
        vortexPoints[7], // Zimbabwe
        vortexPoints[8], // Mohenjo-Daro
        vortexPoints[2], // zurück zu Bermuda
      ],
      type: LeyLineType.vortexRing,
    ));
    
    return connections;
  }
}

/// Ley-Linien-Verbindung Datenmodell
class LeyLineConnection {
  final String name;
  final List<LatLng> points;
  final LeyLineType type;
  
  LeyLineConnection({
    required this.name,
    required this.points,
    required this.type,
  });
}

/// Typen von Ley-Linien für visuelle Unterscheidung
enum LeyLineType {
  ancientMonuments,    // Hauptmonumente (Gold)
  pacificRing,         // Pazifik-Ring (Blau)
  eurasianBelt,        // Eurasische Linie (Grün)
  vortexChain,         // Vortex-Kette (Rot)
  mediterraneanArc,    // Mittelmeer-Bogen (Cyan)
  americanAxis,        // Amerikanische Achse (Orange)
  transPacific,        // Trans-Pazifik (Lila)
  europeanMystical,    // Europäische Mystik (Pink)
  middleEastern,       // Naher Osten (Gelb)
  atlantisTriangle,    // Atlantis-Dreieck (Türkis)
  ufoTriangle,         // UFO-Dreieck (Lime)
  americanVortex,      // Amerikanische Vortexe (Magenta)
  britishLey,          // Britische Ley-Linie (Indigo)
  asianTemples,        // Asiatische Tempel (Amber)
  africanMeridian,     // Afrikanischer Meridian (Teal)
  vortexRing,          // Vortex-Ring (Crimson)
}
