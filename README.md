# 🌌 Weltenbibliothek - Chroniken der verborgenen Pfade

<div align="center">

![App Icon](https://via.placeholder.com/192x192/6B46C1/D4AF37?text=🌌)

**Progressive Web App für alternative Geschichte, verborgenes Wissen und paranormale Phänomene**

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Dokumentation](#-dokumentation)

</div>

---

## 📖 Über das Projekt

**Weltenbibliothek** verbindet wissenschaftliche Echtzeitdaten mit alternativen Perspektiven der Geschichte. Die App bietet:

- 🌊 **Live-Daten**: Schumann-Resonanz, Erdbeben, ISS-Position, Sonnenaktivität
- ⏱️ **Historische Timeline**: Ereignisse von 3000 v.Chr. bis heute mit Multi-Perspektiven
- 📚 **Bibliothek**: Durchsuchbare Sammlung von Mysterien und Verschwörungstheorien
- 🗺️ **Interaktive Karten**: Ley-Linien, Kraftorte, UFO-Sichtungen
- 🤖 **AI-Assistent**: Gemini 2.0 für tiefgehende Analysen

### 🎯 Vision

Eine Plattform für Wissbegierige, die fundierte aber alternative Perspektiven suchen. Wir präsentieren verschiedene Sichtweisen zu historischen Ereignissen und erlauben es Nutzern, selbst zu recherchieren und ihre eigenen Schlüsse zu ziehen.

---

## ✨ Features

### 🏠 Dashboard
- **Kosmischer Status-Monitor** mit Echtzeit-Anzeigen
- **Live-Daten-Integration**:
  - Schumann-Resonanz (7.83 Hz Erdfrequenz)
  - Erdbeben weltweit (24h)
  - ISS Live-Tracking
  - Sonnenaktivität (K-Index)
- **Animierte Visualisierungen**

### ⏱️ Timeline
- **10 Event-Kategorien**:
  - 🏛️ Verlorene Zivilisationen
  - 👽 Außerirdische Kontakte
  - 🔺 Geheimgesellschaften
  - 📡 Technologie-Mysterien
  - 🌀 Dimensionale Anomalien
  - 🔮 Okkulte Ereignisse
  - 📜 Verbotenes Wissen
  - 🛸 UFO-Flotten
  - ⚡ Energiephänomene
  - 🌍 Globale Verschwörungen

- **Multi-Perspektiven-System**:
  - 🏛️ Mainstream
  - 🔍 Alternativ
  - 🕵️ Verschwörung
  - 🧘 Spirituell
  - 🔬 Wissenschaftlich

- **Trust-Level-Bewertung** (1-5 Sterne)
- **Quellen-Dokumentation**

### 📚 Bibliothek
- **Volltext-Suche** durch alle Einträge
- **Favoriten-System**
- **Filter & Sortierung**
- **Grid-Layout** mit Vorschau

### ⚙️ Mehr
- **Einstellungen**: Benachrichtigungen, Theme, Sprache
- **Daten-Export**: Favoriten und Sichtungen
- **Cache-Verwaltung**
- **Info & Support**

---

## 🎨 Design

### Farbpalette
```
Primary:    #6B46C1  (Mystisches Violett)
Secondary:  #D4AF37  (Edles Gold)
Background: #1a1a2e  (Kosmisches Dunkelblau-Schwarz)
Surface:    #16213e  (Strukturierendes Dunkelblau)
Error:      #FF6B6B  (Klares Warnsignal-Rot)
```

### Typografie
- **Überschriften**: Google Fonts "Cinzel" (antike Ausstrahlung)
- **Fließtext**: Google Fonts "Lato" (moderne Lesbarkeit)

### UI/UX
- **Material Design 3** mit Dark Theme
- **Sanfte Animationen** (Fade, Slide, Scale)
- **Responsive Design** für alle Bildschirmgrößen
- **Intuitive Navigation** mit Bottom Bar

---

## 🚀 Installation

### Voraussetzungen
- Flutter SDK 3.35.4+
- Android Studio / VS Code
- Android Device / Emulator (Android 5.0+)

### Quick Start

```bash
# Repository klonen
git clone <your-repo-url>
cd flutter_app

# Dependencies installieren
flutter pub get

# App starten
flutter run

# Release Build (APK)
flutter build apk --release --split-per-abi
```

### APK Download

**Latest Release**: [Download v1.0.0](releases/latest)

- `app-arm64-v8a-release.apk` (~18 MB) - Empfohlen für moderne Geräte
- `app-armeabi-v7a-release.apk` (~15 MB) - Für ältere Geräte
- `app-release.apk` (~50 MB) - Universal APK

---

## 📱 Screenshots

<div align="center">

| Home Dashboard | Timeline | Bibliothek | Mehr |
|:--------------:|:--------:|:----------:|:----:|
| ![Home](https://via.placeholder.com/200x400/1a1a2e/D4AF37?text=Home) | ![Timeline](https://via.placeholder.com/200x400/1a1a2e/D4AF37?text=Timeline) | ![Library](https://via.placeholder.com/200x400/1a1a2e/D4AF37?text=Library) | ![More](https://via.placeholder.com/200x400/1a1a2e/D4AF37?text=More) |

</div>

---

## 🔧 Technologie-Stack

### Frontend
- **Framework**: Flutter 3.35.4
- **Language**: Dart 3.9.2
- **State Management**: Provider
- **UI Components**: Material Design 3

### Backend (Optional)
- **Firebase Core**: 3.6.0
- **Cloud Firestore**: 5.4.3
- **Firebase Storage**: 12.3.2
- **Firebase Auth**: 5.3.1
- **Firebase Messaging**: 15.1.3

### APIs & Services
- **USGS Earthquake API**: Echtzeit-Erdbebendaten
- **Tomsk Observatory**: Schumann-Resonanz
- **NASA Open APIs**: ISS-Position
- **NOAA**: Sonnenaktivität

### Libraries
```yaml
# Networking
http: 1.5.0
dio: 5.7.0

# Storage
hive: 2.2.3
shared_preferences: 2.5.3

# UI/UX
google_fonts: 6.2.1
flutter_animate: 4.5.2
fl_chart: 0.70.2

# Location
geolocator: 13.0.2
flutter_map: 7.0.2
```

---

## 📊 Projektstruktur

```
lib/
├── config/
│   └── app_theme.dart              # Theme & Design-System
├── models/
│   ├── historical_event.dart       # Event-Modell
│   └── sighting.dart               # Sichtungs-Modell
├── screens/
│   ├── home_screen.dart            # Dashboard
│   ├── timeline_screen.dart        # Historische Timeline
│   ├── library_screen.dart         # Bibliothek
│   └── more_screen.dart            # Einstellungen
├── services/
│   ├── earthquake_service.dart     # USGS API
│   ├── schumann_resonance_service.dart
│   └── nasa_data_service.dart      # ISS & Solar
├── widgets/                        # Wiederverwendbare Komponenten
└── main.dart                       # Entry Point

android/
├── app/
│   ├── build.gradle.kts            # Android Build Config
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── res/                    # Icons & Resources

assets/
├── images/                         # Bilder
└── audio/                          # Audio-Dateien
```

---

## 🌐 Live-Datenquellen

### Schumann-Resonanz
- **Quelle**: [Tomsk Space Observatory](http://sosrff.tsu.ru)
- **Update**: Alle 60 Sekunden
- **Metriken**: Frequenz, Amplitude, Qualität

### Erdbeben
- **Quelle**: [USGS Earthquake Hazards](https://earthquake.usgs.gov)
- **Update**: Alle 5 Minuten
- **Daten**: Magnitude, Ort, Tiefe, Koordinaten

### ISS Position
- **Quelle**: [Open Notify API](http://api.open-notify.org)
- **Update**: Alle 10 Sekunden
- **Daten**: Latitude, Longitude, Altitude

### Sonnenaktivität
- **Quelle**: [NOAA Space Weather](https://www.swpc.noaa.gov)
- **Update**: Alle 15 Minuten
- **Daten**: K-Index, Solar Flux, Sonnenflecken

---

## 📚 Dokumentation

- **[Setup-Anleitung](SETUP_DOKUMENTATION.md)** - Detaillierte Installation & Konfiguration
- **[API-Dokumentation](docs/API.md)** - Service-Referenz
- **[Firebase-Setup](docs/FIREBASE.md)** - Backend-Konfiguration
- **[Contributing](CONTRIBUTING.md)** - Mitarbeit am Projekt

---

## 🗺️ Roadmap

### Phase 1 - Core Features ✅
- [x] Dashboard mit Live-Daten
- [x] Historische Timeline
- [x] Bibliothek mit Suche
- [x] Dark Theme Design
- [x] Android APK Build

### Phase 2 - Erweiterte Features 🚧
- [ ] Interaktive 3D-Karte mit Ley-Linien
- [ ] Gemini AI Chat-Integration
- [ ] Community Crowd-Sourcing
- [ ] Binaurale Beats Player
- [ ] Push-Benachrichtigungen
- [ ] Offline-Modus

### Phase 3 - Plattform-Erweiterung 📅
- [ ] iOS App
- [ ] Desktop App (Windows, macOS, Linux)
- [ ] Multi-Sprach-Support
- [ ] Cloud-Synchronisation

---

## 🤝 Contributing

Beiträge sind willkommen! Bitte lies die [Contributing Guidelines](CONTRIBUTING.md) bevor du einen Pull Request erstellst.

### Development Setup

```bash
# Fork & Clone
git clone https://github.com/your-username/weltenbibliothek.git

# Branch erstellen
git checkout -b feature/amazing-feature

# Entwickeln & Testen
flutter test

# Commit & Push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Pull Request erstellen
```

---

## 📄 Lizenz

Dieses Projekt ist lizenziert unter der **MIT License** - siehe [LICENSE](LICENSE) für Details.

---

## 🙏 Credits & Danksagungen

### Open Source Libraries
- [Flutter](https://flutter.dev) - UI Framework
- [Firebase](https://firebase.google.com) - Backend Services
- [Google Fonts](https://fonts.google.com) - Typografie

### Datenquellen
- USGS Earthquake Hazards Program
- Tomsk Space Observatory
- NASA Open APIs
- NOAA Space Weather Prediction Center

### Community
Danke an alle, die an diesem Projekt mitwirken und alternative Perspektiven teilen!

---

## 📞 Support & Kontakt

- **Issues**: [GitHub Issues](https://github.com/your-username/weltenbibliothek/issues)
- **Diskussionen**: [GitHub Discussions](https://github.com/your-username/weltenbibliothek/discussions)
- **Email**: support@weltenbibliothek.app

---

## ⚠️ Disclaimer

Diese App präsentiert alternative Perspektiven und Verschwörungstheorien zu Bildungszwecken. Die dargestellten Inhalte repräsentieren nicht notwendigerweise die Meinung der Entwickler. Nutzer sollten kritisch denken und eigene Recherchen durchführen.

---

<div align="center">

**Entwickelt mit ❤️ und 🌌 kosmischer Energie**

⭐ Wenn dir dieses Projekt gefällt, gib uns einen Stern!

</div>
