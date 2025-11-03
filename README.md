# 🔮 Weltenbibliothek - Chroniken der verborgenen Pfade

<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="Weltenbibliothek Logo" width="192"/>
</p>

<p align="center">
  <strong>Progressive Flutter App für alternative Geschichte, verborgenes Wissen und paranormale Phänomene</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.35.4-blue?logo=flutter" alt="Flutter 3.35.4"/>
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="MIT License"/>
</p>

---

## 📱 Über die App

**Weltenbibliothek** ist eine einzigartige App, die wissenschaftliche Echtzeitdaten mit alternativen Perspektiven der Geschichte vereint. Entdecke verborgenes Wissen, verfolge paranormale Phänomene und erkunde die Chroniken der verborgenen Pfade.

### ✨ Highlights

- 🌍 **Live-Daten Dashboard**: Schumann-Resonanz, Erdbeben, ISS-Position, Sonnenaktivität
- ⏱️ **Historische Timeline**: 10 Event-Kategorien mit Multi-Perspektiven-System
- 📚 **Umfangreiche Bibliothek**: Organisierte Sammlung historischer Mysterien
- 🎨 **Mystisches Dark Theme**: Violett-Gold Design für optimale Atmosphäre
- 🔄 **Auto-Refresh**: Echtzeit-Updates von wissenschaftlichen Quellen
- 📡 **Keine API-Keys**: Nutzt öffentliche APIs ohne Registrierung

---

## 🎯 Features

### 🏠 Home-Dashboard
- **Kosmisches Status-Dashboard** mit Live-Indikatoren
- **Schumann-Resonanz Monitoring** (Tomsk Observatory)
- **Erdbeben-Tracking** (USGS 24h-Daten)
- **ISS Live-Position** (Open-Notify API)
- **Sonnenaktivität** (K-Index, Sonnenstürme)
- Schnellzugriff zu allen App-Bereichen

### ⏱️ Historische Timeline
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

- **Trust-Level-System** (1-5 Sterne)
- **Quellenangaben** mit Verifikation
- **Geografische Verortung** mit Koordinaten

### 📚 Bibliothek
- Grid-Layout mit Kategorie-Karten
- Volltext-Suchfunktion
- Event-Zähler pro Kategorie
- Favoriten-System
- Filter & Sortierung

### ⚙️ Mehr-Bereich
- Push-Benachrichtigungen (für wichtige Ereignisse)
- Daten Export/Import (PDF, JSON, CSV)
- App teilen
- Einstellungen
- Über & Datenschutz

---

## 🎨 Design-System

### Farbpalette
```
Primary Purple:    #6B46C1  // Mystisches Violett - Weisheit & Spiritualität
Secondary Gold:    #D4AF37  // Edles Gold - Altes Wissen & Erleuchtung
Background Dark:   #1a1a2e  // Kosmisches Dunkelblau-Schwarz
Surface Dark:      #16213e  // Strukturierendes Dunkelblau
Error Red:         #FF6B6B  // Klares Warnsignal-Rot
Text White:        #FFFFFF  // Maximale Lesbarkeit
```

### Typografie
- **Überschriften**: Google Fonts "Cinzel" (antike Ausstrahlung)
- **Fließtext**: Google Fonts "Lato" (moderne Lesbarkeit)

---

## 🚀 Installation

### Voraussetzungen
- Flutter SDK 3.35.4
- Android Studio oder VS Code
- Android SDK (API Level 21+)

### Schnellstart
```bash
# Repository klonen
git clone <REPOSITORY_URL>
cd flutter_app

# Dependencies installieren
flutter pub get

# App im Debug-Modus starten
flutter run

# Release APK bauen
flutter build apk --release
```

Für detaillierte Setup-Anleitung siehe [SETUP.md](SETUP.md).

---

## 🔧 Technologie

### Flutter & Dart
- **Flutter**: 3.35.4 (stable)
- **Dart**: 3.9.2

### Firebase (Optional)
- Authentication
- Firestore Database
- Cloud Storage
- Cloud Messaging
- Analytics
- Remote Config

### Kern-Dependencies
- **UI**: google_fonts, flutter_svg, flutter_animate
- **State**: provider
- **Network**: http, dio
- **Storage**: hive, shared_preferences
- **Location**: geolocator, flutter_map
- **Charts**: fl_chart

---

## 📡 APIs & Datenquellen

Die App nutzt ausschließlich öffentliche APIs ohne API-Keys:

1. **USGS Earthquake API**
   - Echtzeit Erdbeben-Daten (24h)
   - Refresh: 5 Minuten

2. **Open-Notify ISS API**
   - Live ISS-Position
   - Refresh: 10 Sekunden

3. **Tomsk Space Observatory**
   - Schumann-Resonanz Spektrogramme
   - Refresh: 60 Sekunden

---

## 📦 Downloads

### Release APK
- **Version**: 1.0.0
- **Größe**: ~51 MB
- **Min. Android**: 5.0 (API 21)
- **Target Android**: 15 (API 35)

Siehe `build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Web-Demo

Die App ist auch als Progressive Web App verfügbar:

```bash
flutter build web --release
python3 -m http.server 8000 --directory build/web
```

---

## 📸 Screenshots

_Coming soon..._

---

## 🗺️ Roadmap

### Version 1.0 ✅
- [x] Home-Dashboard mit Live-Daten
- [x] Historische Timeline
- [x] Bibliothek mit Suche
- [x] Einstellungen & Export
- [x] Dark Theme
- [x] Release APK

### Version 1.1 (Geplant)
- [ ] Interaktive 3D-Weltkarte
- [ ] Ley-Linien Visualisierung
- [ ] Heilige Stätten Marker
- [ ] Erweiterte Filter

### Version 2.0 (Geplant)
- [ ] Gemini 2.0 Flash AI-Chat
- [ ] KI-Analysefunktionen
- [ ] Mustererkennung
- [ ] Predictive Analytics

### Version 2.1 (Geplant)
- [ ] Community Crowd-Sourcing
- [ ] Sichtungs-Meldungen
- [ ] Verifikationssystem
- [ ] Community-Karte

### Version 3.0 (Geplant)
- [ ] Binaurale Beats Player
- [ ] Meditations-Programme
- [ ] Bewusstseins-Frequenzen
- [ ] Timer & Playlists

### Version 3.1 (Geplant)
- [ ] Analytics Dashboard
- [ ] Trend-Analysen
- [ ] Korrelations-Charts
- [ ] Prognose-Modelle

---

## 🤝 Beitragen

Contributions sind willkommen! So kannst du helfen:

1. **Fork** das Repository
2. **Create** einen Feature Branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** deine Änderungen (`git commit -m 'Add AmazingFeature'`)
4. **Push** zum Branch (`git push origin feature/AmazingFeature`)
5. **Open** einen Pull Request

---

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe [LICENSE](LICENSE) für Details.

---

## 🙏 Danksagungen

- **Flutter Team** für das großartige Framework
- **Firebase** für Backend-Services
- **USGS** für Erdbeben-Daten
- **Open-Notify** für ISS-Tracking
- **Tomsk Space Observatory** für Schumann-Resonanz-Daten
- **Google Fonts** für Cinzel & Lato Schriftarten

---

## 📞 Kontakt & Support

- **Issues**: [GitHub Issues](https://github.com/username/weltenbibliothek/issues)
- **Email**: support@weltenbibliothek.app
- **Website**: https://weltenbibliothek.app

---

## ⚠️ Disclaimer

Diese App dient zu Informations- und Unterhaltungszwecken. Die präsentierten alternativen Perspektiven und Theorien sollten kritisch betrachtet werden. Wir ermutigen zu eigener Recherche und wissenschaftlichem Denken.

---

<p align="center">
  Entwickelt mit 🔮 von der Weltenbibliothek Community<br>
  <strong>© 2025 Weltenbibliothek. Alle Rechte vorbehalten.</strong>
</p>

---

**Entdecke die verborgenen Pfade. Erweitere dein Bewusstsein. Erkenne die Wahrheit.** ✨
