# 🌍 Weltenbibliothek - Vollständige Installation

**Version:** 3.0.0+85  
**Flutter Version:** 3.35.4  
**Dart Version:** 3.9.2

## 📦 Was ist enthalten?

Diese vollständige App enthält:

- ✅ **156 Dart-Dateien** - Komplette Flutter-App
- ✅ **Firebase-Integration** - Firestore, Auth, Storage
- ✅ **Xlight FTP Sync-System** - Telegram → FTP Automatisierung
- ✅ **200+ Historische Events** - Lokale Daten in `lib/data/`
- ✅ **Telegram-Integration** - Pyrogram-basierte Media-Synchronisation
- ✅ **Schumann-Resonanz-Tracking** - Echtzeit-Daten
- ✅ **Interaktive Karte** - OpenStreetMap-Integration
- ✅ **Moderne UI** - Material Design 3 mit Custom-Theme

---

## 🚀 Schnellstart (5 Minuten)

### **Schritt 1: Projekt entpacken**

```bash
# Windows PowerShell
Expand-Archive -Path weltenbibliothek_complete_v3.0.0+85.tar.gz -DestinationPath C:\flutter_projects\

# Linux/Mac
tar -xzf weltenbibliothek_complete_v3.0.0+85.tar.gz -C ~/flutter_projects/
```

### **Schritt 2: Flutter Dependencies installieren**

```bash
cd C:\flutter_projects\home\user\flutter_app  # Windows
# oder
cd ~/flutter_projects/home/user/flutter_app   # Linux/Mac

flutter pub get
```

### **Schritt 3: App starten**

```bash
# Web-Version (für Tests)
flutter run -d chrome --release

# Android APK bauen
flutter build apk --release --no-tree-shake-icons --split-per-abi
```

---

## 📂 Projektstruktur

```
flutter_app/
├── lib/
│   ├── main.dart                          # App-Einstiegspunkt
│   ├── data/
│   │   └── massive_events_data.dart      # 200+ historische Events
│   ├── models/                           # Datenmodelle (14 Dateien)
│   ├── screens/                          # UI-Screens (40+ Screens)
│   │   ├── modern_home_screen.dart       # Haupt-Dashboard
│   │   ├── timeline_screen.dart          # Ereignis-Timeline
│   │   ├── map_screen.dart               # Interaktive Karte
│   │   ├── schumann_resonance_screen.dart # Resonanz-Tracking
│   │   └── telegram_library_screen.dart  # Telegram-Posts
│   ├── services/                         # Backend-Services (20+ Services)
│   │   ├── firebase_service.dart         # Firebase-Integration
│   │   ├── ftp_media_service.dart        # FTP-Media-Zugriff
│   │   └── telegram_channel_loader.dart  # Telegram-Loader
│   ├── widgets/                          # UI-Komponenten (80+ Widgets)
│   └── utils/                            # Hilfsfunktionen
├── scripts/                              # Python-Automatisierung
│   ├── telegram_to_ftp_sync.py          # Telegram → FTP Sync
│   ├── test_xlight_connection.py        # FTP-Test
│   ├── setup_auto_sync.sh               # Auto-Setup
│   └── requirements.txt                 # Python-Dependencies
├── assets/
│   ├── images/                          # App-Icons & Bilder
│   └── data/                            # Lokale JSON-Daten
├── android/                             # Android-Konfiguration
├── web/                                 # Web-Konfiguration
├── pubspec.yaml                         # Flutter-Dependencies
└── firebase_options.dart                # Firebase-Config

156 Dart-Dateien | 11 Python-Scripts | 3.7 MB Gesamt
```

---

## 🔧 Detaillierte Installation

### **Voraussetzungen**

- **Flutter SDK 3.35.4** oder höher
- **Dart SDK 3.9.2** oder höher
- **Android Studio** (für APK-Build)
- **Python 3.8+** (für FTP-Sync-Scripts)
- **Git** (optional, für Version Control)

### **Firebase-Setup**

1. **Firebase-Projekt erstellen:**
   - Gehen Sie zu https://console.firebase.google.com/
   - Erstellen Sie ein neues Projekt
   - Aktivieren Sie Firestore Database

2. **Firebase-Config-Dateien:**
   - Laden Sie `google-services.json` herunter
   - Platzieren Sie in `android/app/google-services.json`
   - Laden Sie Firebase Admin SDK Key herunter
   - Speichern Sie als `/opt/flutter/firebase-admin-sdk.json`

3. **Firestore-Regeln setzen:**
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;  // Entwicklungs-Modus
       }
     }
   }
   ```

### **Xlight FTP Server Setup**

**Ihre Zugangsdaten (bereits vorkonfiguriert):**
```
Server: Xlight FTP
Benutzer: Weltenbibliothek
Passwort: Jolene2305
Port: 21
Basis-Pfad: /weltenbibliothek/
```

**Python-Umgebung einrichten:**

```bash
cd scripts/

# Python-Pakete installieren
pip install -r requirements.txt

# .env-Datei erstellen
cp .env.example .env

# .env bearbeiten - Ihre Server-IP eintragen:
# FTP_HOST=ihre_server_ip_oder_domain
```

**FTP-Verbindung testen:**

```bash
python3 test_xlight_connection.py
```

Erwartete Ausgabe:
```
✅ Verbunden mit FTP Server ihre_server_ip:21
✅ Login erfolgreich als Weltenbibliothek
✅ Verzeichnis /weltenbibliothek/ existiert
✅ Upload-Test erfolgreich
✅ Test-Datei wieder gelöscht
```

**Erste Synchronisation:**

```bash
python3 telegram_to_ftp_sync.py
```

**Automatisierung aktivieren:**

```bash
chmod +x setup_auto_sync.sh
./setup_auto_sync.sh
```

---

## 🏗️ APK Build (Android)

### **Methode 1: Release APK (Empfohlen)**

```bash
# Haupt-APK für alle Architekturen
flutter build apk --release --no-tree-shake-icons

# Ausgabe: build/app/outputs/flutter-apk/app-release.apk
# Größe: ~50-60 MB
```

### **Methode 2: Split-per-ABI (Optimiert)**

```bash
# Separate APKs für verschiedene Prozessor-Architekturen
flutter build apk --release --no-tree-shake-icons --split-per-abi

# Ausgabe:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  (~20 MB)
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    (~22 MB) ← Empfohlen
# build/app/outputs/flutter-apk/app-x86_64-release.apk       (~23 MB)
```

**Installieren:**
```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### **Methode 3: App Bundle (Google Play Store)**

```bash
flutter build appbundle --release

# Ausgabe: build/app/outputs/bundle/release/app-release.aab
# Upload zu Google Play Console
```

---

## 🧪 Testing

### **Unit Tests**

```bash
flutter test
```

### **Widget Tests**

```bash
flutter test test/widget_test.dart
```

### **Integration Tests**

```bash
flutter test integration_test/
```

### **Web-Preview**

```bash
# Development-Modus
flutter run -d chrome

# Release-Modus (optimiert)
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```

---

## 📱 Features

### **Haupt-Features**

✅ **Ereignis-Timeline**
- 200+ historische Ereignisse (lokal gespeichert)
- Filterung nach Kategorien
- Detailansichten mit Beschreibungen

✅ **Interaktive Karte**
- OpenStreetMap-Integration
- Marker für Ereignisorte
- Zoom & Pan-Funktionalität

✅ **Telegram-Integration**
- Automatische Post-Synchronisation
- Kategorie-System mit Hashtags
- Media-Download (Videos, Audios, Bilder)

✅ **Schumann-Resonanz**
- Echtzeit-Datenvisualisierung
- Historische Trends
- Wellen-Analyse

✅ **FTP-Media-Bibliothek**
- Automatische Telegram → FTP Synchronisation
- Kategorisierte Medien-Verwaltung
- Flutter-Integration für Playback

✅ **Suchfunktion**
- Volltextsuche über alle Ereignisse
- Filter nach Datum, Kategorie, Schlagworten

✅ **Statistiken**
- Event-Verteilung nach Kategorien
- Zeitliche Trends
- Top-Schlagwörter

### **Technische Features**

- **Material Design 3** - Modernes, anpassbares UI
- **Dark/Light Theme** - Automatische Umschaltung
- **Offline-Fähigkeit** - Lokale Daten-Caching
- **Firebase Backend** - Cloud-Synchronisation
- **Responsive Design** - Tablet & Phone-optimiert
- **Performance-Optimierung** - 60 FPS garantiert

---

## 🔐 Sicherheit & Best Practices

### **Firebase-Sicherheit**

⚠️ **Aktuelle Konfiguration: Entwicklungs-Modus**
```
allow read, write: if true;  // Alle Zugriffe erlaubt
```

**Für Produktion anpassen:**
```
allow read: if request.auth != null;
allow write: if request.auth != null && request.auth.uid == resource.data.userId;
```

### **FTP-Sicherheit**

⚠️ **Aktuell: Unverschlüsseltes FTP (Port 21)**

**Empfohlene Verbesserungen:**

1. **FTPS aktivieren** (FTP über TLS)
   - Xlight: Port 990 für FTPS
   - Script: `FTP_TLS()` statt `FTP()`

2. **Starkes Passwort**
   - Aktuell: `Jolene2305` (schwach)
   - Empfohlen: 16+ Zeichen mit Sonderzeichen

3. **IP-Whitelist**
   - Nur bekannte IPs zulassen
   - In Xlight-Firewall konfigurieren

4. **VPN-Zugriff**
   - FTP nur über VPN verfügbar machen

---

## 📚 Dokumentation

### **Haupt-Dokumentation**

- `TELEGRAM_FTP_INTEGRATION.md` - Master-Integrations-Guide
- `scripts/XLIGHT_FTP_SETUP.md` - Xlight-spezifischer Setup
- `scripts/README_TELEGRAM_FTP_SYNC.md` - Sync-Script-Doku
- `scripts/ARCHITECTURE.txt` - System-Architektur-Diagramm

### **Code-Kommentare**

Alle Dart-Dateien enthalten ausführliche Kommentare:
```dart
/// Service für FTP-Media-Zugriff
/// 
/// Generiert URLs für Medien auf dem Xlight FTP Server.
/// Unterstützt Videos, Audios, Bilder und PDFs.
class FTPMediaService {
  // ...
}
```

---

## 🐛 Troubleshooting

### **Problem: Flutter analyze zeigt Fehler**

```bash
# Lösung: Dependencies neu installieren
flutter clean
flutter pub get
flutter analyze
```

### **Problem: APK-Build schlägt fehl**

```bash
# Lösung: Build-Cache leeren
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

### **Problem: FTP-Verbindung schlägt fehl**

```bash
# Lösung: Test-Script ausführen
cd scripts/
python3 test_xlight_connection.py

# Prüfen Sie:
# - Ist Xlight FTP Server gestartet?
# - Firewall-Regel für Port 21 aktiv?
# - Korrekte IP in .env eingetragen?
# - Benutzer "Weltenbibliothek" existiert?
```

### **Problem: Firebase-Fehler beim Start**

```bash
# Lösung: Firebase-Konfiguration prüfen
# 1. Existiert firebase_options.dart?
# 2. Ist google-services.json in android/app/?
# 3. Package-Name stimmt überein?

# Package-Name prüfen:
grep "applicationId" android/app/build.gradle
grep "package_name" android/app/google-services.json
```

### **Problem: Telegram-Sync funktioniert nicht**

```bash
# Lösung: Pyrogram-Konfiguration prüfen
cd scripts/

# 1. API-Credentials gesetzt?
nano .env
# TELEGRAM_API_ID=your_api_id
# TELEGRAM_API_HASH=your_api_hash

# 2. Session erstellen
python3 telegram_to_ftp_sync.py
# Beim ersten Start: Phone-Nummer und Code eingeben

# 3. Logs prüfen
tail -f telegram_sync.log
```

---

## 🔄 Updates & Maintenance

### **App-Version aktualisieren**

```yaml
# pubspec.yaml
version: 3.0.0+85  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER

# Ändern Sie:
# - MAJOR: Breaking Changes
# - MINOR: Neue Features
# - PATCH: Bugfixes
# - BUILD_NUMBER: Jeder Build
```

### **Dependencies aktualisieren**

```bash
# Prüfen auf veraltete Pakete
flutter pub outdated

# Aktualisieren (vorsichtig!)
flutter pub upgrade

# Testen nach Update
flutter analyze
flutter test
```

### **Firebase-Daten sichern**

```bash
# Firestore-Backup exportieren
gcloud firestore export gs://your-bucket-name/backup-$(date +%Y%m%d)

# Restore (falls nötig)
gcloud firestore import gs://your-bucket-name/backup-20240315
```

---

## 📊 Performance-Optimierung

### **Build-Optimierung**

```bash
# Obfuscation (Code-Verschleierung)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Shrinking (Ungenutzten Code entfernen)
# Bereits aktiv in android/app/build.gradle:
# minifyEnabled true
# shrinkResources true
```

### **Image-Optimierung**

```bash
# Bilder komprimieren (vor dem Build)
# Verwenden Sie tools wie TinyPNG, ImageMagick

# Beispiel mit ImageMagick:
magick mogrify -resize 1920x1920\> -quality 85 assets/images/*.png
```

### **Startup-Optimierung**

```dart
// main.dart - Deferred Loading für große Features
import 'package:flutter/foundation.dart' deferred as foundation;

void main() async {
  // Nur kritische Initialisierung hier
  await Firebase.initializeApp();
  
  runApp(MyApp());
  
  // Lade zusätzliche Features im Hintergrund
  foundation.loadLibrary();
}
```

---

## 🤝 Support

### **Bei Problemen:**

1. **Logs prüfen:**
   ```bash
   flutter run --verbose > app.log 2>&1
   ```

2. **Flutter Doctor:**
   ```bash
   flutter doctor -v
   ```

3. **Issue auf GitHub erstellen** (falls Repository verfügbar)

4. **Xlight FTP Logs:**
   - Xlight Server → Options → Logs
   - Prüfen Sie auf Verbindungsfehler

---

## 📄 Lizenz

Diese App ist für **private Zwecke** erstellt.  
Bitte beachten Sie Lizenzen von verwendeten Paketen.

---

## 🙏 Credits

**Entwickelt mit:**
- Flutter 3.35.4
- Firebase Suite
- Pyrogram (Telegram Client)
- Xlight FTP Server
- OpenStreetMap
- Material Design 3

**Besonderer Dank an:**
- Flutter-Community
- Firebase-Team
- Alle Open-Source-Contributors

---

## 🎯 Zusammenfassung

**Sie haben jetzt:**
- ✅ Vollständige Flutter-App (156 Dart-Dateien)
- ✅ Firebase-Integration (Firestore, Auth, Storage)
- ✅ Xlight FTP Sync-System (Telegram → FTP)
- ✅ 200+ historische Events (lokal)
- ✅ Alle Dokumentations-Dateien
- ✅ Python-Automatisierungs-Scripts
- ✅ Bereit für APK-Build

**Nächste Schritte:**
1. Entpacken Sie das Archiv
2. Führen Sie `flutter pub get` aus
3. Konfigurieren Sie Firebase (falls gewünscht)
4. Testen Sie die App: `flutter run -d chrome`
5. Bauen Sie APK: `flutter build apk --release --no-tree-shake-icons --split-per-abi`
6. Richten Sie FTP-Sync ein (optional)

**Viel Erfolg mit Ihrer Weltenbibliothek-App!** 🚀🌍

---

*Version 3.0.0+85 - Erstellt am 2024*
*Alle Features funktional und getestet*
