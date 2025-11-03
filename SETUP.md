# Weltenbibliothek - Setup-Dokumentation

## 📱 Projektübersicht

**Weltenbibliothek - Chroniken der verborgenen Pfade**

Eine Progressive Flutter App für alternative Geschichte, verborgenes Wissen, Live-Wissenschaftsdaten und paranormale Phänomene. Die App vereint wissenschaftliche Echtzeitdaten mit alternativen Perspektiven der Geschichte.

- **Version**: 1.0.0
- **Plattform**: Android (API Level 21+)
- **Framework**: Flutter 3.35.4
- **Backend**: Firebase (optional)

---

## 🎯 Features

### Kern-Funktionen
1. **Home-Dashboard**
   - Kosmisches Dashboard mit Live-Status
   - Schumann-Resonanz Monitoring
   - Erdbeben-Tracking (24h)
   - ISS Position & Sonnenaktivität
   - Schnellzugriff zu allen Features

2. **Historische Timeline**
   - 10 Event-Kategorien mit Farb-Kodierung
   - Multi-Perspektiven-System (Mainstream, Alternativ, Verschwörung, Spirituell, Wissenschaftlich)
   - Filter nach Kategorien
   - Trust-Level-System (1-5 Sterne)
   - Bottom-Sheet Detail-Ansichten

3. **Bibliothek**
   - Grid-Layout mit Kategorie-Karten
   - Volltext-Suchfunktion
   - Event-Zähler pro Kategorie
   - Favoriten-System (vorbereitet)

4. **Mehr-Bereich**
   - Push-Benachrichtigungen (vorbereitet)
   - Daten Export/Import
   - App teilen
   - Über & Datenschutz

### Live-Daten Services
- **Schumann-Resonanz**: Tomsk Space Observatory (60s Refresh)
- **Erdbeben**: USGS GeoJSON API (5min Refresh)
- **ISS Position**: Open-Notify API (10s Refresh)
- **Sonnenaktivität**: Simuliert (15min Refresh)

---

## 🔧 Technologie-Stack

### Flutter Dependencies
```yaml
# Firebase (LOCKED versions)
firebase_core: 3.6.0
cloud_firestore: 5.4.3
firebase_storage: 12.3.2
firebase_messaging: 15.1.3
firebase_analytics: 11.3.3
firebase_auth: 5.3.1
firebase_remote_config: 5.1.3

# State Management
provider: 6.1.5+1

# UI & Design
google_fonts: 6.2.1       # Cinzel & Lato Fonts
flutter_svg: 2.0.15
flutter_animate: 4.5.2

# Networking
http: 1.5.0
dio: 5.7.0

# Local Storage
hive: 2.2.3
hive_flutter: 1.1.0
shared_preferences: 2.5.3

# Location & Maps
geolocator: 13.0.2
flutter_map: 7.0.2
latlong2: 0.9.1

# Media & Utils
audioplayers: 6.1.0
url_launcher: 6.3.1
intl: 0.20.1
share_plus: 10.1.2
cached_network_image: 3.4.1
fl_chart: 0.70.2
```

---

## 🚀 Installation & Einrichtung

### 1. Voraussetzungen
- Flutter SDK 3.35.4
- Android Studio oder VS Code
- Android SDK (API Level 21+)
- Git

### 2. Projekt klonen
```bash
git clone <REPOSITORY_URL>
cd flutter_app
```

### 3. Dependencies installieren
```bash
flutter pub get
```

### 4. Firebase Setup (Optional)

Die App funktioniert auch ohne Firebase im Offline-Modus mit Sample-Daten.

Für vollständige Firebase-Integration:

#### a) Firebase-Projekt erstellen
1. Gehe zu [Firebase Console](https://console.firebase.google.com/)
2. Erstelle ein neues Projekt: "Weltenbibliothek"
3. Aktiviere folgende Services:
   - Authentication (Anonyme Anmeldung)
   - Firestore Database
   - Storage
   - Cloud Messaging
   - Analytics
   - Remote Config

#### b) Android App registrieren
1. Im Firebase-Projekt → "Android App hinzufügen"
2. Package Name: `com.weltenbibliothek.weltenbibliothek`
3. App-Spitzname: "Weltenbibliothek"
4. Debug Signing Certificate SHA-1 (optional für Release)

#### c) google-services.json herunterladen
1. Lade `google-services.json` herunter
2. Platziere sie in: `android/app/google-services.json`

#### d) firebase_options.dart erstellen
```bash
# FlutterFire CLI installieren (falls nicht vorhanden)
dart pub global activate flutterfire_cli

# Firebase-Konfiguration generieren
flutterfire configure
```

Wähle:
- Plattformen: Android, Web
- Firebase-Projekt: Dein erstelltes Projekt

Dies erstellt automatisch `lib/firebase_options.dart`.

#### e) Firestore Security Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // Nur für Development!
    }
  }
}
```

**WICHTIG**: Für Production müssen strengere Security Rules definiert werden!

---

## 🔥 Firebase Datenstruktur (Optional)

### Collections

#### 1. `historical_events` Collection
```typescript
{
  id: string,
  title: string,
  description: string,
  date: Timestamp,
  category: string, // 'lostCivilizations', 'alienContact', etc.
  perspectives: string[], // ['mainstream', 'conspiracy', etc.]
  sources: string[],
  trustLevel: number, // 1-5
  mediaUrls: string[],
  latitude: number,
  longitude: number,
  locationName: string,
  additionalData: map
}
```

#### 2. `sightings` Collection
```typescript
{
  id: string,
  userId: string,
  title: string,
  description: string,
  type: string, // 'lights', 'ufoUap', 'paranormal', etc.
  timestamp: Timestamp,
  latitude: number,
  longitude: number,
  locationName: string,
  mediaUrls: string[],
  trustScore: number, // 0-100
  verified: boolean,
  reportCount: number
}
```

#### 3. `users` Collection (für erweiterte Features)
```typescript
{
  id: string,
  displayName: string,
  favoriteEvents: string[],
  favoriteSightings: string[],
  notificationSettings: {
    earthquakes: boolean,
    solarActivity: boolean,
    newEvents: boolean
  }
}
```

---

## 🎨 Design-System

### Farbpalette
```dart
Primary Purple:    #6B46C1  // Mystisches Violett
Secondary Gold:    #D4AF37  // Edles Gold
Background Dark:   #1a1a2e  // Kosmisches Dunkelblau-Schwarz
Surface Dark:      #16213e  // Strukturierendes Dunkelblau
Error Red:         #FF6B6B  // Klares Warnsignal-Rot
Text White:        #FFFFFF  // Maximale Lesbarkeit
```

### Event-Kategorie-Farben
```dart
Lost Civilizations:    #FF8C42  // Orange
Alien Contact:         #4ADE80  // Grün
Secret Societies:      #EF4444  // Rot
Tech Mysteries:        #06B6D4  // Cyan
Dimensional Anomalies: #8B5CF6  // Violett
Occult Events:         #EC4899  // Magenta
Forbidden Knowledge:   #92400E  // Braun
UFO Fleets:            #3B82F6  // Blau
Energy Phenomena:      #FBBF24  // Gelb
Global Conspiracies:   #991B1B  // Dunkelrot
```

### Typografie
- **Überschriften**: Google Fonts "Cinzel" (antike, mystische Ausstrahlung)
- **Fließtext**: Google Fonts "Lato" (moderne Lesbarkeit)

---

## 📦 Build & Deployment

### Debug Build
```bash
flutter run
```

### Release APK
```bash
# Universal APK (alle Architekturen)
flutter build apk --release

# Split per ABI (kleinere Dateien)
flutter build apk --release --split-per-abi
```

APK-Ausgabe: `build/app/outputs/flutter-apk/`

### App Bundle (für Google Play Store)
```bash
flutter build appbundle --release
```

AAB-Ausgabe: `build/app/outputs/bundle/release/`

### Web Build
```bash
flutter build web --release
```

Web-Ausgabe: `build/web/`

---

## 🧪 Testen

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Analyse
```bash
flutter analyze
```

---

## 🔐 Signing für Release

Für die Veröffentlichung im Google Play Store benötigst du ein Signing-Zertifikat.

### 1. Keystore erstellen
```bash
keytool -genkey -v -keystore ~/weltenbibliothek-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias weltenbibliothek
```

### 2. key.properties erstellen
Erstelle `android/key.properties`:
```properties
storePassword=<dein-store-password>
keyPassword=<dein-key-password>
keyAlias=weltenbibliothek
storeFile=<pfad-zu-keystore>/weltenbibliothek-key.jks
```

### 3. build.gradle.kts anpassen
Füge in `android/app/build.gradle.kts` hinzu:

```kotlin
// Lade key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 🌐 API-Endpunkte

Die App nutzt folgende öffentliche APIs (keine API-Keys erforderlich):

1. **USGS Earthquake API**
   - URL: `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson`
   - Rate Limit: Keine
   - Dokumentation: https://earthquake.usgs.gov/earthquakes/feed/

2. **ISS Position API**
   - URL: `http://api.open-notify.org/iss-now.json`
   - Rate Limit: Keine
   - Dokumentation: http://open-notify.org/Open-Notify-API/ISS-Location-Now/

3. **Schumann-Resonanz**
   - URL: `http://sosrff.tsu.ru/new/shm.jpg`
   - Spektrogramm-Bilder (Auto-Refresh mit Cache-Busting)

---

## 📱 App-Architektur

```
lib/
├── main.dart                    # App Entry Point
├── config/
│   └── app_theme.dart           # Design-System & Themes
├── models/
│   ├── historical_event.dart   # Event-Datenmodell
│   └── sighting.dart            # Sichtungs-Datenmodell
├── screens/
│   ├── home_screen.dart         # Dashboard mit Live-Daten
│   ├── timeline_screen.dart    # Historische Timeline
│   ├── library_screen.dart      # Bibliothek Grid
│   └── more_screen.dart         # Einstellungen & Info
├── services/
│   ├── earthquake_service.dart  # Erdbeben API Service
│   ├── schumann_resonance_service.dart # Schumann Service
│   └── nasa_data_service.dart   # ISS & Solar Service
└── widgets/                     # Wiederverwendbare Widgets
```

---

## 🐛 Troubleshooting

### Problem: "Firebase not initialized"
**Lösung**: Die App läuft auch ohne Firebase. Für Firebase-Integration folge dem Firebase Setup oben.

### Problem: Gradle Build Fehler
**Lösung**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Problem: "SDK version mismatch"
**Lösung**: Stelle sicher, dass du Flutter 3.35.4 verwendest:
```bash
flutter --version
```

### Problem: API-Daten laden nicht
**Lösung**: Überprüfe Internetverbindung. Die Services haben Fallback-Mechanismen mit Cache.

---

## 📄 Lizenz & Rechtliches

### Open-Source Libraries
Diese App verwendet Open-Source Software unter verschiedenen Lizenzen. Siehe `pubspec.yaml` für Details.

### API-Nutzung
- USGS Earthquake API: Public Domain
- Open-Notify ISS API: Public Domain
- Tomsk Space Observatory: Wissenschaftliche Nutzung

### Datenschutz
Die App sammelt keine persönlichen Daten ohne Zustimmung. Für Firebase-Integration gelten die Firebase-Datenschutzrichtlinien.

---

## 🤝 Support & Community

### Feedback & Bug Reports
Bitte erstelle ein Issue im GitHub-Repository.

### Feature Requests
Feature-Wünsche sind willkommen! Erstelle ein Issue mit dem Label "enhancement".

---

## 🚀 Roadmap (Zukünftige Features)

- [ ] Interaktive 3D-Weltkarte mit Ley-Linien
- [ ] Gemini 2.0 Flash AI-Chat Integration
- [ ] Community Crowd-Sourcing für Sichtungen
- [ ] Binaurale Beats Audio-Player
- [ ] Analytics Dashboard mit Charts
- [ ] Offline-Modus mit vollständiger Datensynchronisation
- [ ] Push-Benachrichtigungen für signifikante Ereignisse
- [ ] Multi-Language Support (EN, DE, ES, FR)
- [ ] iOS Version

---

## 📞 Kontakt

Entwickelt mit 🔮 von der Weltenbibliothek Community

Version: 1.0.0  
Build Date: November 2025

---

**Viel Erfolg mit der Weltenbibliothek! 🌍✨**
