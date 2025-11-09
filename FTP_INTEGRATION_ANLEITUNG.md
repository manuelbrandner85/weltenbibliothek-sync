# 🎯 FTP-Integration in bestehende App - ANLEITUNG

## ✅ Was wurde geändert?

Ihre **bestehende App bleibt komplett gleich**! Nur folgende Erweiterungen:

1. ✅ **Telegram-Models** erweitert - Laden jetzt auch FTP-URLs (`mediaUrl`)
2. ✅ **Python-Script** erstellt - Synchronisiert Telegram → FTP → Firestore
3. ✅ **HTTP-Server** hinzugefügt - Macht FTP-Dateien für Flutter verfügbar

**KEINE neuen Screens!** Medien werden in den bestehenden Telegram-Ansichten angezeigt.

---

## 📋 SCHRITT 1: Python-Script konfigurieren

### Datei: `scripts/telegram_ftp_firestore_sync.py`

```python
# Ihre Telegram API-Credentials (von https://my.telegram.org/)
API_ID = "12345678"  # ← Ihre API ID
API_HASH = "abcdef1234567890"  # ← Ihr API Hash
TELEGRAM_CHANNEL = "@IhrKanalName"  # ← Ihr Telegram-Kanal

# FTP ist bereits konfiguriert:
FTP_HOST = "Weltenbibliothek.ddns.net"
FTP_USER = "Weltenbibliothek"
FTP_PASS = "Jolene2305"

# HTTP-URL für Flutter:
HTTP_BASE_URL = "http://Weltenbibliothek.ddns.net:8080"

# Firebase-Credentials:
FIREBASE_CRED = "firebase_credentials.json"  # Pfad anpassen!

# Firestore Collection (WICHTIG: Ihre bestehende!)
COLLECTION = "telegram_media"  # ← Oder wie Ihre Collection heißt
```

---

## 📋 SCHRITT 2: HTTP-Server starten

### Datei: `scripts/simple_http_server.py`

**WICHTIG:** Passen Sie den Pfad an!

```python
# Zeigt auf Ihr Xlight FTP Home Directory
FTP_ROOT = r"C:\weltenbibliothek"  # Windows
# FTP_ROOT = "/weltenbibliothek"    # Linux
```

**Starten:**

```bash
cd scripts
python3 simple_http_server.py
```

Output:
```
✅ Serviere Dateien aus: C:\weltenbibliothek
🚀 HTTP-Server läuft auf Port 8080
📡 Zugriff: http://localhost:8080
   Flutter: http://Weltenbibliothek.ddns.net:8080
```

**Server läuft dauerhaft im Hintergrund!**

---

## 📋 SCHRITT 3: Telegram → FTP Sync ausführen

```bash
cd scripts
python3 telegram_ftp_firestore_sync.py
```

**Was passiert:**

1. 📥 Lädt Medien von Ihrem Telegram-Kanal
2. 📤 Uploaded zu Xlight FTP (`/videos`, `/audios`, `/images`, `/pdfs`)
3. ☁️ Speichert Metadaten in Firestore Collection `telegram_media`
4. ✅ Generiert HTTP-URLs für Flutter

**Output:**
```
🚀 Starte Sync...
✅ video1.mp4 (video)
✅ audio1.mp3 (audio)
✅ image1.jpg (image)
✅ Sync abgeschlossen!
```

---

## 📋 SCHRITT 4: Firestore-Struktur prüfen

Ihre Firestore-Collection sieht jetzt so aus:

```
telegram_media/
├── video1.mp4
│   ├── channelUsername: "IhrKanal"
│   ├── channelTitle: "Weltenbibliothek"
│   ├── text: "Video-Beschreibung"
│   ├── date: Timestamp
│   ├── category: "allgemein"
│   ├── mediaType: "video"
│   ├── mediaUrl: "http://Weltenbibliothek.ddns.net:8080/videos/video1.mp4"  ← NEU!
│   ├── fileName: "video1.mp4"
│   └── fileSize: 12345678
│
├── audio1.mp3
│   └── mediaUrl: "http://Weltenbibliothek.ddns.net:8080/audios/audio1.mp3"
│
└── image1.jpg
    └── mediaUrl: "http://Weltenbibliothek.ddns.net:8080/images/image1.jpg"
```

---

## 📋 SCHRITT 5: Flutter-App testen

**KEINE Änderungen nötig!**

Die App lädt automatisch die FTP-URLs aus Firestore:

1. ✅ **Videos** - Werden über `TelegramVideo.videoUrl` abgespielt
2. ✅ **Audios** - Werden über `TelegramAudio.downloadUrl` abgespielt
3. ✅ **Bilder** - Werden über `TelegramPhoto.imageUrl` angezeigt
4. ✅ **PDFs** - Werden über `TelegramDocument.downloadUrl` geöffnet

**Testen:**

```bash
flutter run -d chrome --release
```

Gehen Sie zu Ihren bestehenden Telegram-Screens und die Medien sollten automatisch abgespielt werden!

---

## 🎯 Wie es funktioniert

### **Bestehende App-Struktur (UNVERÄNDERT):**

```dart
// lib/screens/telegram_content_screen.dart
// Nutzt weiterhin TelegramVideo.videoUrl

final video = TelegramVideo(doc.id, doc.data());
videoUrl = video.videoUrl;  // ← Lädt jetzt FTP-URL!
```

### **Models erweitert (AUTOMATISCH):**

```dart
// lib/models/telegram_models.dart

String? get videoUrl {
  // PRIORITÄT 1: FTP/HTTP URL (vom Python-Script)
  if (data['mediaUrl'] != null) {
    return data['mediaUrl'];  // ← NEU!
  }
  // PRIORITÄT 2: Alte Struktur (Fallback)
  return data['video_url'];
}
```

**Resultat:** Ihre App nutzt jetzt automatisch FTP-URLs, wenn vorhanden!

---

## 🔧 Troubleshooting

### **Problem: "Video kann nicht abgespielt werden"**

**Lösung:**

1. **HTTP-Server läuft?**
   ```bash
   # In neuem Terminal:
   cd scripts
   python3 simple_http_server.py
   ```

2. **Firewall-Regel für Port 8080?**
   - Windows: Firewall → Neue Regel → Port 8080 → Verbindung zulassen
   - Router: Port-Forwarding 8080 → Ihr PC

3. **URL korrekt in Firestore?**
   - Öffnen Sie Firebase Console
   - Collection `telegram_media` → Dokument öffnen
   - Prüfen Sie `mediaUrl`-Feld
   - Sollte sein: `http://Weltenbibliothek.ddns.net:8080/videos/datei.mp4`

### **Problem: "Keine Medien in App sichtbar"**

**Lösung:**

1. **Python-Script ausgeführt?**
   ```bash
   cd scripts
   python3 telegram_ftp_firestore_sync.py
   ```

2. **Firestore Collection korrekt?**
   - Im Script: `COLLECTION = "telegram_media"`
   - Muss mit Ihrer App übereinstimmen!

3. **Flutter-App neu starten:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### **Problem: "FTP-Upload schlägt fehl"**

**Lösung:**

1. **Xlight FTP Server läuft?**
   - Öffnen Sie Xlight auf Windows
   - Status sollte "Running" sein

2. **Credentials korrekt?**
   - User: `Weltenbibliothek`
   - Pass: `Jolene2305`

3. **Test-FTP-Verbindung:**
   ```python
   from ftplib import FTP
   ftp = FTP()
   ftp.connect("Weltenbibliothek.ddns.net", 21)
   ftp.login("Weltenbibliothek", "Jolene2305")
   print("✅ FTP funktioniert!")
   ftp.quit()
   ```

---

## 📊 Automatisierung (Optional)

### **Windows Task Scheduler**

Sync automatisch alle 30 Minuten:

1. Task Scheduler öffnen
2. Neue Aufgabe erstellen
3. Trigger: Alle 30 Minuten
4. Aktion: `python C:\...\scripts\telegram_ftp_firestore_sync.py`

### **Linux Cron-Job**

```bash
# Crontab bearbeiten
crontab -e

# Alle 30 Minuten ausführen
*/30 * * * * cd /pfad/zu/scripts && python3 telegram_ftp_firestore_sync.py
```

---

## 🎉 Zusammenfassung

**Was Sie haben:**

✅ **Bestehende App** - Funktioniert weiterhin normal
✅ **FTP als Storage** - Ersetzt Firebase Storage
✅ **Automatische Sync** - Telegram → FTP → Firestore
✅ **HTTP-Zugriff** - Flutter kann Medien abspielen
✅ **KEINE UI-Änderungen** - Alles in bestehenden Screens

**Nächste Schritte:**

1. Python-Script konfigurieren (`API_ID`, `API_HASH`, `TELEGRAM_CHANNEL`)
2. HTTP-Server starten (`python3 simple_http_server.py`)
3. Sync ausführen (`python3 telegram_ftp_firestore_sync.py`)
4. Flutter-App testen (`flutter run`)

**FERTIG!** 🚀

Ihre App zeigt jetzt automatisch die FTP-Medien in den bestehenden Telegram-Ansichten an!
