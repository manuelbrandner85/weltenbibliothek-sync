# 📡 Telegram → FTP Sync System

Automatisches Synchronisations-System für Telegram-Medien zu FTP Server und Flutter App.

## 🎯 Features

- ✅ Automatischer Download von Telegram-Medien (Videos, Audios, Bilder, PDFs)
- ✅ Kategorisierung basierend auf Hashtags
- ✅ Upload zu FTP Server
- ✅ Duplikat-Erkennung (keine doppelten Uploads)
- ✅ Metadaten-Tracking
- ✅ Fehlerbehandlung und Logging

## 📋 Voraussetzungen

### 1. Python Packages installieren

```bash
pip install pyrogram tgcrypto python-dotenv
```

### 2. Telegram API Credentials

1. Gehe zu: https://my.telegram.org/apps
2. Erstelle eine neue App
3. Notiere dir:
   - `API_ID` (Nummer)
   - `API_HASH` (String)

### 3. FTP Server

- FTP Host-Adresse
- FTP Zugangsdaten (User/Password)
- Zugriff auf Server

## 🚀 Installation

### Schritt 1: .env Datei erstellen

```bash
cd scripts
cp .env.example .env
```

### Schritt 2: .env ausfüllen

```env
# Telegram API
API_ID=1234567
API_HASH=abcdef1234567890abcdef1234567890

# Telegram Channel
CHANNEL=@your_channel_name

# FTP Server
FTP_HOST=123.45.67.89
FTP_PORT=21
FTP_USER=Weltenbibliothek
FTP_PASS=Jolene2305
FTP_BASE_PATH=/weltenbibliothek
```

### Schritt 3: Erste Synchronisation

```bash
python telegram_to_ftp_sync.py
```

## 📊 Verwendung

### Manueller Sync

```bash
cd scripts
python telegram_to_ftp_sync.py
```

### Automatischer Sync (Cron)

Füge zu `/etc/crontab` hinzu:

```bash
# Alle 15 Minuten synchronisieren
*/15 * * * * cd /path/to/scripts && python telegram_to_ftp_sync.py
```

## 📂 Verzeichnisstruktur

```
FTP Server:
/weltenbibliothek/
  ├── videos/          # Video-Dateien
  ├── audios/          # Audio/Podcast-Dateien
  ├── images/          # Bilder
  ├── pdfs/            # PDF-Dokumente
  └── documents/       # Sonstige Dokumente

Lokal:
scripts/
  ├── telegram_to_ftp_sync.py   # Haupt-Script
  ├── .env                       # Konfiguration (nicht committen!)
  ├── sync_metadata.json         # Tracking welche Nachrichten bereits synced
  └── downloads/                 # Temporärer Download-Ordner
```

## 🏷️ Kategorien-System

Das Script erkennt Kategorien automatisch aus Hashtags:

- `#technologie` oder `#tech` → **tech_mysteries**
- `#mystik` oder `#occult` → **mysticism**
- `#kosmos` oder `#space` → **cosmos**
- `#verboten` oder `#forbidden` → **forbidden**
- `#paranormal` → **paranormal**
- Ohne Hashtag → **general**

### Beispiel Telegram-Post:

```
Hier ist ein spannendes Video über alte Technologien! 
#technologie #mysterien

🎥 Video: Die Antikythera-Mechanismus
```

→ Wird kategorisiert als **tech_mysteries**

## 🔄 Sync-Status

Das Script speichert Metadaten in `sync_metadata.json`:

```json
{
  "synced_messages": [12345, 12346, 12347],
  "last_sync": "2025-11-08T01:30:00"
}
```

## 🛠️ Troubleshooting

### Problem: "Failed to connect to FTP"

**Lösung:**
- Prüfe FTP Host-Adresse
- Prüfe Firewall-Regeln (Port 21 offen?)
- Teste FTP-Verbindung mit FileZilla

### Problem: "Telegram API error"

**Lösung:**
- Prüfe API_ID und API_HASH
- Erstelle neue Session: Lösche `weltenbibliothek_sync.session`

### Problem: "Permission denied" auf FTP

**Lösung:**
- Prüfe FTP User-Berechtigungen
- Stelle sicher, dass Upload-Rechte vorhanden sind

## 📱 Flutter App Integration

Die FTP URLs können direkt in der Flutter App verwendet werden:

```dart
// Beispiel: FTP URL in Flutter
String videoUrl = "ftp://your-server.com/weltenbibliothek/videos/video.mp4";

// Für HTTP-Zugriff (empfohlen):
// Richte FTP → HTTP Proxy ein oder nutze HTTP Server
```

### HTTP-Zugriff einrichten (empfohlen)

Für bessere Flutter-Kompatibilität, richte einen HTTP Server ein:

```nginx
# Nginx Config für FTP-Zugriff via HTTP
location /media/ {
    alias /path/to/ftp/weltenbibliothek/;
    autoindex on;
}
```

Dann in Flutter:
```dart
String videoUrl = "https://your-domain.com/media/videos/video.mp4";
```

## 🔐 Sicherheit

⚠️ **Wichtig:**
- `.env` Datei NIEMALS committen!
- Füge `.env` zu `.gitignore` hinzu
- Verwende starke FTP-Passwörter
- Aktiviere FTP over TLS (FTPS) wenn möglich

## 📞 Support

Bei Fragen oder Problemen:
1. Prüfe Logs: `python telegram_to_ftp_sync.py`
2. Teste FTP-Verbindung manuell
3. Prüfe Telegram API Limits

## 🎉 Erfolg!

Nach erfolgreichem Setup solltest du sehen:

```
📡 TELEGRAM → FTP SYNC SYSTEM
✅ FTP verbunden: your-server.com
📦 Starte Sync von @your_channel...
✅ Hochgeladen: ftp://server.com/weltenbibliothek/videos/video1.mp4
✅ Hochgeladen: ftp://server.com/weltenbibliothek/audios/podcast1.mp3
✅ Sync abgeschlossen!
   📥 15 neue Dateien hochgeladen
   ⏭️ 5 Nachrichten übersprungen
```
