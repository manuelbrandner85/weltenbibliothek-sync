# 🌌 Weltenbibliothek - Setup & Installationsanleitung

## 📱 App-Übersicht

**Name**: Weltenbibliothek - Chroniken der verborgenen Pfade  
**Version**: 1.0.0  
**Plattformen**: Android (APK), Web  
**Package**: `com.weltenbibliothek.weltenbibliothek`

Eine progressive Web App für alternative Geschichte, verborgenes Wissen, Live-Wissenschaftsdaten, Verschwörungstheorien und paranormale Phänomene.

---

## 🎯 Features

### ✅ Implementiert (Phase 1)

#### 🏠 Home Screen
- **Kosmisches Dashboard** mit Echtzeit-Status
- **Live-Daten-Integration**:
  - 🌊 Schumann-Resonanz (Tomsk Observatory)
  - 🌍 Erdbeben (USGS API)
  - 🛰️ ISS Live-Position (NASA API)
  - ☀️ Sonnenaktivität (K-Index, Solar Flux)
- **Schnellzugriff-Buttons** zu allen Hauptfunktionen
- Animierte Partikel-Effekte

#### ⏱️ Timeline Screen
- **Historische Ereignisse** von 3000 v.Chr. bis heute
- **10 Event-Kategorien**:
  - 🏛️ Verlorene Zivilisationen (Atlantis, Mu)
  - 👽 Außerirdische Kontakte (Roswell, Phoenix Lights)
  - 🔺 Geheimgesellschaften (Illuminati, Freimaurer)
  - 📡 Technologie-Mysterien (Antikythera, Philadelphia Experiment)
  - 🌀 Dimensionale Anomalien (Bermuda-Dreieck, Montauk)
  - 🔮 Okkulte Ereignisse (Crowley, Thule)
  - 📜 Verbotenes Wissen (Alexandria, Voynich)
  - 🛸 UFO-Flotten (Nürnberg 1561, Mexico City)
  - ⚡ Energiephänomene (Tunguska, Tesla)
  - 🌍 Globale Verschwörungen (MK-Ultra, HAARP)
- **Multi-Perspektiven-System**:
  - 🏛️ Mainstream
  - 🔍 Alternativ
  - 🕵️ Verschwörung
  - 🧘 Spirituell
  - 🔬 Wissenschaftlich
- **Trust-Level-System** (1-5 Sterne)
- **Detailansicht** mit Quellen und Metadaten

#### 📚 Bibliothek Screen
- **Volltext-Suche** durch alle Einträge
- **Grid-Layout** mit Event-Cards
- **Favoriten-System**
- **Statistik-Dashboard**

#### ⚙️ Mehr Screen
- Benutzer-Profil mit Statistiken
- Einstellungen (Benachrichtigungen, Sprache, Theme)
- Daten-Management (Export, Cache)
- Info & Datenschutz

### 🎨 Design-System
- **Dark Theme** mit mystischer Ausstrahlung
- **Farbpalette**:
  - Primary: #6B46C1 (Mystisches Violett)
  - Secondary: #D4AF37 (Edles Gold)
  - Background: #1a1a2e (Kosmisch)
  - Surface: #16213e (Dunkelblau)
- **Typografie**:
  - Überschriften: Cinzel (antik, geheimnisvoll)
  - Fließtext: Lato (modern, lesbar)
- **Animationen**: Sanfte Fade/Slide-Transitions

---

## 🔧 Technische Architektur

### Flutter Version
- **Flutter**: 3.35.4 (stable)
- **Dart**: 3.9.2

### Dependencies
```yaml
# Core Firebase (LOCKED versions)
firebase_core: 3.6.0
cloud_firestore: 5.4.3
firebase_storage: 12.3.2
firebase_messaging: 15.1.3
firebase_analytics: 11.3.3
firebase_auth: 5.3.1
firebase_remote_config: 5.1.3

# State Management & UI
provider: 6.1.5+1
google_fonts: 6.2.1
flutter_svg: 2.0.15
flutter_animate: 4.5.2

# Networking
http: 1.5.0
dio: 5.7.0

# Storage
hive: 2.2.3
hive_flutter: 1.1.0
shared_preferences: 2.5.3

# Location & Maps
geolocator: 13.0.2
flutter_map: 7.0.2
latlong2: 0.9.1

# Media
audioplayers: 6.1.0
url_launcher: 6.3.1

# Utils
intl: 0.20.1
share_plus: 10.1.2
cached_network_image: 3.4.1
fl_chart: 0.70.2
```

### Projektstruktur
```
lib/
├── config/
│   └── app_theme.dart           # Design-System & Theme
├── models/
│   ├── historical_event.dart    # Event-Datenmodell
│   └── sighting.dart            # Community-Sichtungen
├── screens/
│   ├── home_screen.dart         # Dashboard & Live-Daten
│   ├── timeline_screen.dart     # Historische Timeline
│   ├── library_screen.dart      # Bibliothek & Suche
│   └── more_screen.dart         # Einstellungen
├── services/
│   ├── earthquake_service.dart  # USGS Erdbeben API
│   ├── schumann_resonance_service.dart  # Tomsk Observatory
│   └── nasa_data_service.dart   # ISS & Solar Data
├── widgets/                     # Wiederverwendbare UI-Komponenten
└── main.dart                    # App Entry Point
```

---

## 🚀 Installation & Setup

### Voraussetzungen
- Flutter SDK 3.35.4+
- Android Studio / VS Code
- Git

### Projekt-Setup

1. **Repository Klonen**
```bash
git clone <your-repo-url>
cd flutter_app
```

2. **Dependencies Installieren**
```bash
flutter pub get
```

3. **Android Emulator / Device Verbinden**
```bash
flutter devices
```

4. **App Starten (Debug)**
```bash
# Android
flutter run

# Web
flutter run -d chrome
```

5. **Release Build**
```bash
# Android APK (split-per-ABI)
flutter build apk --release --split-per-abi

# Web
flutter build web --release
```

---

## 🔥 Firebase Integration (Optional)

⚠️ **Hinweis**: Die App funktioniert aktuell mit simulierten Daten. Firebase-Integration ist optional für Backend-Features.

### Firebase Setup (wenn gewünscht)

1. **Firebase Projekt Erstellen**
   - https://console.firebase.google.com/
   - Neues Projekt anlegen

2. **Android App Hinzufügen**
   - Package Name: `com.weltenbibliothek.weltenbibliothek`
   - `google-services.json` herunterladen
   - Nach `android/app/` kopieren

3. **Firestore Database Erstellen**
   - Build → Firestore Database → Create Database
   - Produktionsmodus oder Testmodus wählen
   - Region auswählen

4. **Collections Erstellen**
```
events/          # Historische Ereignisse
  ├── id
  ├── title
  ├── description
  ├── date
  ├── category
  ├── perspectives
  ├── sources
  ├── trustLevel
  ├── latitude
  ├── longitude
  └── locationName

sightings/       # Community-Meldungen
  ├── id
  ├── userId
  ├── title
  ├── description
  ├── type
  ├── timestamp
  ├── latitude
  ├── longitude
  └── trustScore

users/           # Benutzer-Profile
  ├── uid
  ├── displayName
  ├── favorites[]
  └── sightingsCount
```

5. **Security Rules (Development)**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // Nur für Entwicklung!
    }
  }
}
```

6. **FlutterFire konfigurieren**
```bash
# FlutterFire CLI installieren
dart pub global activate flutterfire_cli

# Firebase konfigurieren
flutterfire configure
```

---

## 📦 APK Download & Installation

### Release APKs (Split-per-ABI)

Die App wird in separaten APKs pro Architektur bereitgestellt für optimale Größe:

- **app-armeabi-v7a-release.apk** (~15 MB)  
  → Für ältere 32-bit Android-Geräte
  
- **app-arm64-v8a-release.apk** (~18 MB)  
  → Für moderne 64-bit Android-Geräte (empfohlen)
  
- **app-x86_64-release.apk** (~20 MB)  
  → Für x86-64 Emulatoren
  
- **app-release.apk** (~50 MB)  
  → Universal APK (funktioniert auf allen Architekturen)

### Installation auf Android-Gerät

1. APK auf Gerät übertragen
2. Dateien-App öffnen
3. APK antippen
4. "Installation aus unbekannten Quellen" erlauben (falls erforderlich)
5. "Installieren" antippen

---

## 🌐 Live-Daten APIs

### Schumann-Resonanz
- **Quelle**: Tomsk Space Observatory
- **URL**: `http://sosrff.tsu.ru/new/shm.jpg`
- **Update-Intervall**: 60 Sekunden
- **Daten**: Frequenz (7.83 Hz), Amplitude, Qualität

### Erdbeben
- **Quelle**: USGS Earthquake Hazards Program
- **API**: `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson`
- **Update-Intervall**: 5 Minuten
- **Daten**: Magnitude, Ort, Tiefe, Zeit, Koordinaten

### ISS Position
- **Quelle**: Open Notify API
- **API**: `http://api.open-notify.org/iss-now.json`
- **Update-Intervall**: 10 Sekunden
- **Daten**: Latitude, Longitude, Altitude, Velocity

### Sonnenaktivität
- **Quelle**: NOAA Space Weather Prediction Center
- **Daten**: K-Index, Solar Flux, Sunspot Number
- **Update-Intervall**: 15 Minuten

---

## 🐛 Troubleshooting

### Build-Fehler

**Problem**: "Execution failed for task ':app:lintVitalRelease'"
```bash
# Lösung: Lint-Checks deaktivieren
# In android/app/build.gradle.kts hinzufügen:
android {
    lintOptions {
        checkReleaseBuilds = false
    }
}
```

**Problem**: "Out of memory"
```bash
# Lösung: Gradle Memory erhöhen
# In android/gradle.properties:
org.gradle.jvmargs=-Xmx4096m
```

### Runtime-Fehler

**Problem**: Live-Daten laden nicht
- Internetverbindung prüfen
- Firewall/Proxy-Einstellungen überprüfen
- API-Endpunkte sind erreichbar

**Problem**: App stürzt beim Start ab
- Mindestanforderungen prüfen (Android 5.0+)
- Cache löschen: Settings → Apps → Weltenbibliothek → Clear Cache

---

## 📊 Performance

### Optimierungen
- **Tree-Shaking**: Font-Dateien auf benötigte Glyphen reduziert (99.4%)
- **Split-APKs**: Separate Builds pro Architektur für kleinere Dateigrößen
- **Lazy Loading**: Services starten erst nach erstem Frame
- **Caching**: Lokale Speicherung von Favoriten und Einstellungen

### Größen-Vergleich
- **Web Build**: ~3 MB (komprimiert)
- **APK arm64-v8a**: ~18 MB
- **APK Universal**: ~50 MB

---

## 🔮 Roadmap (Phase 2 - Geplant)

### Erweiterte Features
- [ ] **3D-Interaktive Karte** mit Ley-Linien und Kraftorten
- [ ] **Gemini AI Chat-Integration** für Verschwörungstheorie-Analysen
- [ ] **Community Crowd-Sourcing** für UFO-Sichtungen
- [ ] **Binaurale Beats Player** für Bewusstseins-Frequenzen
- [ ] **Analytics Dashboard** mit Trend-Analysen
- [ ] **Push-Benachrichtigungen** bei Magnitude ≥6.0 Erdbeben
- [ ] **Offline-Modus** mit lokaler Datenspeicherung
- [ ] **Multi-Sprach-Support** (EN, DE, ES, FR)

---

## 📄 Lizenz & Credits

### Open Source Libraries
- Flutter Framework (BSD-3-Clause)
- Google Fonts (Apache 2.0)
- Material Icons (Apache 2.0)

### Datenquellen
- USGS Earthquake Hazards Program
- Tomsk Space Observatory
- NASA Open APIs
- NOAA Space Weather

### Disclaimer
Diese App präsentiert alternative Perspektiven und Verschwörungstheorien zu Bildungszwecken. Die dargestellten Inhalte repräsentieren nicht notwendigerweise die Meinung der Entwickler. Nutzer sollten kritisch denken und eigene Recherchen durchführen.

---

## 🤝 Support & Kontakt

**GitHub**: <your-github-url>  
**Issues**: <your-issues-url>  
**Diskussionen**: <your-discussions-url>

---

**Entwickelt mit ❤️ und 🌌 kosmischer Energie**
