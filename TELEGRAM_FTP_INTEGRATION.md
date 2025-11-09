# 📡 Telegram → Xlight FTP → Flutter App Integration

Vollständiges System für automatische Synchronisation von Telegram-Medien zu Xlight FTP Server und Integration in Flutter App.

---

## 🎯 Übersicht

```
Telegram Channel
      ↓
  Python Script (Pyrogram)
      ↓
  Xlight FTP Server
      ↓
  Flutter App
```

---

## 🔧 Ihre Xlight FTP Konfiguration

- **Server:** Xlight FTP Server
- **Benutzername:** `Weltenbibliothek`
- **Passwort:** `Jolene2305`
- **Host:** Ihre Server-IP oder Domain

---

## 📂 Projektstruktur

```
flutter_app/
├── scripts/                           # Sync-Scripts
│   ├── telegram_to_ftp_sync.py       # 🔥 Hauptscript
│   ├── test_xlight_connection.py     # 🧪 Test-Tool
│   ├── setup_auto_sync.sh            # ⚙️ Auto-Setup
│   ├── requirements.txt              # 📦 Python Dependencies
│   ├── .env.example                  # 📝 Konfiguration Template
│   ├── .env                          # 🔐 Deine Konfiguration (nicht committen!)
│   ├── sync_metadata.json            # 📊 Sync-Status (automatisch erstellt)
│   ├── downloads/                    # 📥 Temp Download-Ordner
│   ├── README_TELEGRAM_FTP_SYNC.md   # 📖 Allgemeine Dokumentation
│   └── XLIGHT_FTP_SETUP.md           # 🔧 Xlight-spezifische Anleitung
│
├── lib/
│   ├── services/
│   │   └── ftp_media_service.dart    # 📱 Flutter FTP Service
│   └── widgets/
│       └── ftp_media_player_example.dart  # 🎥 Beispiel-Widget
│
└── TELEGRAM_FTP_INTEGRATION.md       # 📋 Diese Datei
```

---

## 🚀 Quick Start (5 Minuten)

### 1. **FTP-Verbindung testen**

```bash
cd scripts
python3 test_xlight_connection.py
```

Falls `.env` noch nicht existiert, wird eine Anleitung angezeigt.

### 2. **`.env` Datei erstellen**

```bash
cp .env.example .env
nano .env
```

**Wichtig ausfüllen:**
- `FTP_HOST` = Deine Server-IP (z.B. `192.168.1.100`)
- `API_ID` = Von https://my.telegram.org/apps
- `API_HASH` = Von https://my.telegram.org/apps  
- `CHANNEL` = Dein Telegram Kanal (z.B. `@dein_kanal`)

### 3. **Python Packages installieren**

```bash
pip install -r requirements.txt
```

### 4. **Ersten Sync durchführen**

```bash
python3 telegram_to_ftp_sync.py
```

Beim ersten Start:
- Telegram Login-Aufforderung erscheint
- Gib deine Telefonnummer ein
- Gib den Code aus Telegram ein
- Session wird gespeichert

### 5. **Automatischen Sync einrichten**

```bash
./setup_auto_sync.sh
```

Wähle Intervall (z.B. alle 15 Minuten).

---

## 📋 Detaillierte Anleitungen

### 📘 Allgemeine Synchronisation
→ Siehe: `scripts/README_TELEGRAM_FTP_SYNC.md`

### 🔧 Xlight FTP Server Setup
→ Siehe: `scripts/XLIGHT_FTP_SETUP.md`

---

## 🎥 Beispiel: Medien in Flutter App laden

```dart
import 'package:flutter/material.dart';
import 'services/ftp_media_service.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Generiere FTP URL
    final videoUrl = FTPMediaService().getVideoUrl('mein_video.mp4');
    
    // Initialisiere Video Player
    final controller = VideoPlayerController.network(videoUrl);
    
    return VideoPlayer(controller);
  }
}
```

Vollständiges Beispiel: `lib/widgets/ftp_media_player_example.dart`

---

## 📊 Kategorien-System

Das Script kategorisiert automatisch basierend auf Telegram-Hashtags:

| Hashtag | Kategorie | FTP-Ordner |
|---------|-----------|------------|
| `#technologie` `#tech` | tech_mysteries | `/videos/` |
| `#mystik` `#occult` | mysticism | `/videos/` |
| `#kosmos` `#space` | cosmos | `/videos/` |
| `#verboten` `#forbidden` | forbidden | `/videos/` |
| `#paranormal` | paranormal | `/videos/` |
| (keine) | general | `/videos/` |

**Telegram-Post Beispiel:**
```
📱 Neues Video über alte Technologien!

Die Geheimnisse der Pyramiden 🏛️

#technologie #mysterien
```

→ Wird hochgeladen nach: `ftp://server/weltenbibliothek/videos/pyramiden.mp4`

---

## 🔍 Troubleshooting

### ❌ "Connection refused"

**Ursache:** Xlight Server läuft nicht oder falsche IP

**Lösung:**
```bash
# Prüfe Server-Status (Windows)
tasklist | findstr Xlight

# Teste Verbindung
telnet your-server-ip 21
```

### ❌ "530 Login authentication failed"

**Ursache:** Falsche Zugangsdaten oder Benutzer nicht aktiviert

**Lösung:**
1. Öffne Xlight Control Panel
2. Gehe zu **Users** → **Weltenbibliothek**
3. Prüfe:
   - Password: `Jolene2305`
   - Status: **Enabled**
   - Permissions: **All** aktiviert

### ❌ "550 Permission denied"

**Ursache:** Keine Schreibrechte

**Lösung:**
1. Xlight Panel → **Users** → **Weltenbibliothek**
2. Aktiviere alle Permissions:
   - ✅ Read
   - ✅ Write
   - ✅ Delete
   - ✅ Create Directory

### ❌ Telegram API Error

**Lösung:**
```bash
# Lösche alte Session
rm weltenbibliothek_sync.session

# Starte neu
python3 telegram_to_ftp_sync.py
```

---

## 🔐 Sicherheit

### ⚠️ Wichtig:

1. **`.env` niemals committen!**
   ```bash
   echo ".env" >> .gitignore
   ```

2. **Firewall konfigurieren:**
   - Nur Port 21 (FTP) öffnen
   - Optional: IP-Whitelist in Xlight

3. **FTPS aktivieren (empfohlen):**
   - Xlight Panel → **SSL Certificate**
   - Aktiviere TLS/SSL
   - Ändere Port zu 990 (FTPS)

4. **Starke Passwörter:**
   - Aktuell: `Jolene2305`
   - Empfohlen: Längeres Passwort mit Sonderzeichen

---

## 📱 Flutter App HTTP-Zugriff (empfohlen)

Für bessere Performance und Kompatibilität, richte HTTP-Zugriff ein:

### Option 1: IIS vor Xlight

```
IIS → Virtual Directory → C:\ftp-data\weltenbibliothek
```

URLs werden zu:
```
https://your-domain.com/media/videos/video.mp4
```

### Option 2: Nginx Proxy

```nginx
location /media/ {
    alias C:/ftp-data/weltenbibliothek/;
    autoindex on;
}
```

### Flutter Integration:

```dart
// In ftp_media_service.dart anpassen:
static const String _httpProxyUrl = 'https://your-domain.com/media';
static const bool _useHttpProxy = true;
```

---

## 📈 Monitoring & Logs

### Sync-Logs ansehen

```bash
tail -f scripts/sync.log
```

### Cron-Jobs prüfen

```bash
crontab -l
```

### Sync-Status prüfen

```bash
cat scripts/sync_metadata.json
```

Zeigt:
- Welche Nachrichten bereits synchronisiert wurden
- Letzter Sync-Zeitpunkt

---

## 🎉 Erfolgreiche Installation

Nach vollständigem Setup siehst du:

```
✅ FTP-Verbindung funktioniert
✅ Xlight Server erreichbar
✅ Telegram API verbunden
✅ Automatischer Sync läuft alle 15 Minuten
✅ Flutter App kann Medien laden
```

---

## 📞 Support

Bei Problemen:

1. **Test-Script ausführen:**
   ```bash
   python3 scripts/test_xlight_connection.py
   ```

2. **Logs prüfen:**
   ```bash
   tail -f scripts/sync.log
   ```

3. **Xlight Server Logs:**
   - Xlight Panel → **Logs** → **View Logs**

4. **FileZilla Test:**
   - Host: Deine Server-IP
   - User: Weltenbibliothek
   - Pass: Jolene2305
   - Port: 21

---

## 🚀 Nächste Schritte

1. ✅ Teste FTP-Verbindung
2. ✅ Teste ersten Sync
3. ✅ Richte Cron-Job ein
4. ✅ Integriere in Flutter App
5. ⭐ Optional: FTPS/HTTPS für Sicherheit

---

**🎊 Viel Erfolg mit deinem Telegram → Xlight FTP → Flutter System!**
