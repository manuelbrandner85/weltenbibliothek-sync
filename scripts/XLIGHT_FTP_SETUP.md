# 🔧 Xlight FTP Server Setup für Telegram Sync

## 📋 Server-Informationen

**FTP Server:** Xlight FTP Server  
**Benutzername:** Weltenbibliothek  
**Passwort:** Jolene2305

---

## 🎯 Schritt 1: Xlight FTP Server vorbereiten

### A) Ordnerstruktur auf Server erstellen

In Xlight FTP Server, erstelle folgende Ordner für den Benutzer "Weltenbibliothek":

```
/weltenbibliothek/
  ├── videos/          # Video-Dateien
  ├── audios/          # Audio/Podcast-Dateien  
  ├── images/          # Bilder
  ├── pdfs/            # PDF-Dokumente
  └── documents/       # Sonstige Dokumente
```

### B) Benutzer-Berechtigungen in Xlight setzen

1. Öffne **Xlight FTP Server Control Panel**
2. Gehe zu **Users** → **Weltenbibliothek**
3. Setze Berechtigungen:
   - ✅ **Read** (Lesen)
   - ✅ **Write** (Schreiben)
   - ✅ **Delete** (Löschen)
   - ✅ **Append** (Anhängen)
   - ✅ **Create Directory** (Ordner erstellen)
   - ✅ **Delete Directory** (Ordner löschen)

### C) Virtual Path Mapping (Optional)

Wenn die Ordner woanders liegen als im Standard-Home:

1. Gehe zu **Virtual Directories** im Xlight Panel
2. Mappe `/weltenbibliothek/` → `C:\ftp-data\weltenbibliothek\` (oder dein Pfad)

---

## 🔧 Schritt 2: .env Datei konfigurieren

Erstelle die `.env` Datei im `scripts/` Ordner:

```bash
cd scripts
cp .env.example .env
nano .env
```

**Inhalt der .env Datei:**

```env
# ===== TELEGRAM API =====
# Von: https://my.telegram.org/apps
API_ID=your_api_id_here
API_HASH=your_api_hash_here

# ===== TELEGRAM CHANNEL =====
CHANNEL=@your_channel_name

# ===== XLIGHT FTP SERVER =====
# Deine Server-IP oder Domain
FTP_HOST=123.45.67.89
# Standard FTP Port
FTP_PORT=21
# Xlight FTP Benutzername
FTP_USER=Weltenbibliothek
# Xlight FTP Passwort
FTP_PASS=Jolene2305
# Basis-Pfad auf Server
FTP_BASE_PATH=/weltenbibliothek

# ===== OPTIONAL: FIREBASE =====
FIREBASE_PROJECT_ID=weltenbibliothek-5d21f
```

### 🔐 Wichtig: Server-IP/Domain herausfinden

**Wenn Xlight lokal läuft:**
```bash
# Windows CMD:
ipconfig

# Suche nach "IPv4-Adresse"
# Beispiel: 192.168.1.100
```

**Wenn Xlight auf externem Server:**
- Verwende die öffentliche IP oder Domain
- Beispiel: `ftp.ihr-domain.de` oder `123.45.67.89`

---

## 🧪 Schritt 3: FTP-Verbindung testen

### A) Mit FileZilla testen

1. **FileZilla öffnen**
2. **Verbindung:**
   - Host: `ftp://your-server-ip`
   - Benutzername: `Weltenbibliothek`
   - Passwort: `Jolene2305`
   - Port: `21`

3. **Klicke "Schnellverbindung"**

✅ **Erfolg:** Du siehst die Ordner auf dem Server  
❌ **Fehler:** Prüfe Firewall/Port-Freigaben

### B) Mit Python-Script testen

```python
import ftplib

FTP_HOST = "your-server-ip"  # z.B. 192.168.1.100
FTP_PORT = 21
FTP_USER = "Weltenbibliothek"
FTP_PASS = "Jolene2305"

try:
    ftp = ftplib.FTP()
    ftp.connect(FTP_HOST, FTP_PORT)
    ftp.login(FTP_USER, FTP_PASS)
    
    print("✅ FTP Verbindung erfolgreich!")
    print("📂 Ordner auf Server:")
    ftp.retrlines('LIST')
    
    ftp.quit()
except Exception as e:
    print(f"❌ Fehler: {e}")
```

Speichere als `test_ftp.py` und führe aus:
```bash
python test_ftp.py
```

---

## 🚀 Schritt 4: Python-Packages installieren

```bash
cd scripts
pip install -r requirements.txt
```

Oder manuell:
```bash
pip install pyrogram tgcrypto python-dotenv
```

---

## 📱 Schritt 5: Telegram API Setup

### A) API Keys erstellen

1. Gehe zu: **https://my.telegram.org/apps**
2. Melde dich mit deiner Telegram-Nummer an
3. Klicke **"API development tools"**
4. Fülle aus:
   - **App title:** Weltenbibliothek Sync
   - **Short name:** weltenbib
   - **Platform:** Desktop
5. **Speichere API_ID und API_HASH**

### B) Teste Telegram-Verbindung

```bash
cd scripts
python telegram_to_ftp_sync.py
```

Beim ersten Start:
- Es öffnet sich eine Telegram-Login-Aufforderung
- Gib deine Telefonnummer ein
- Gib den Code aus Telegram ein
- Session wird in `weltenbibliothek_sync.session` gespeichert

---

## ⚙️ Schritt 6: Automatischen Sync einrichten

### Option A: Setup-Script verwenden

```bash
cd scripts
./setup_auto_sync.sh
```

Folge den Anweisungen:
1. Wähle Sync-Intervall (z.B. alle 15 Minuten)
2. Script richtet Cron-Job automatisch ein

### Option B: Manuell Cron-Job erstellen

```bash
crontab -e
```

Füge hinzu (Beispiel: Alle 15 Minuten):
```cron
*/15 * * * * cd /path/to/scripts && python3 telegram_to_ftp_sync.py >> sync.log 2>&1
```

---

## 🔥 Schritt 7: Firewall/Port-Freigaben (Xlight)

### Windows Firewall

1. **Windows Firewall** öffnen
2. **Erweiterte Einstellungen** → **Eingehende Regeln**
3. **Neue Regel** erstellen:
   - **Regel-Typ:** Port
   - **Protokoll:** TCP
   - **Port:** 21 (FTP)
   - **Aktion:** Verbindung zulassen
   - **Name:** Xlight FTP Server

### Xlight FTP Server Einstellungen

1. Öffne **Xlight Server Control Panel**
2. Gehe zu **Options** → **SSL Certificate**
3. Optional: Aktiviere **TLS/SSL** für sichere Verbindung (FTPS)

### Router Port-Forwarding (für externes Zugriff)

Falls Server hinter Router:
1. Router-Admin öffnen (z.B. 192.168.1.1)
2. **Port Forwarding** / **Virtual Server** einrichten:
   - **External Port:** 21
   - **Internal Port:** 21  
   - **Internal IP:** Server-IP (z.B. 192.168.1.100)
   - **Protocol:** TCP

---

## 📊 Schritt 8: Ersten Sync durchführen

```bash
cd scripts
python3 telegram_to_ftp_sync.py
```

**Erwartete Ausgabe:**

```
============================================================
📡 TELEGRAM → FTP SYNC SYSTEM
============================================================

✅ Python 3 gefunden
✅ pip3 gefunden
✅ .env Datei gefunden
✅ FTP verbunden: 192.168.1.100
📦 Starte Sync von @your_channel...
📊 Limit: 100 neueste Nachrichten

✅ Hochgeladen: ftp://192.168.1.100/weltenbibliothek/videos/video1.mp4
✅ Hochgeladen: ftp://192.168.1.100/weltenbibliothek/audios/podcast1.mp3
✅ Hochgeladen: ftp://192.168.1.100/weltenbibliothek/images/photo1.jpg
✅ Hochgeladen: ftp://192.168.1.100/weltenbibliothek/pdfs/doc1.pdf

📊 Status: 4 synchronisiert, 0 übersprungen

✅ Sync abgeschlossen!
   📥 4 neue Dateien hochgeladen
   ⏭️ 0 Nachrichten übersprungen

🎉 Sync erfolgreich abgeschlossen!
```

---

## 🌐 Schritt 9: HTTP-Zugriff einrichten (für Flutter App)

### Option A: IIS/Apache/Nginx vor Xlight FTP

Richte einen HTTP Server ein, der auf FTP-Ordner zeigt:

**Nginx Beispiel:**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location /media/ {
        alias C:/ftp-data/weltenbibliothek/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
```

**IIS Beispiel:**
1. IIS Manager öffnen
2. **Add Virtual Directory**
3. Alias: `/media`
4. Physical Path: `C:\ftp-data\weltenbibliothek`
5. **Directory Browsing** aktivieren

### Option B: Xlight Web Access (falls verfügbar)

Einige Xlight-Versionen haben integriertes Web-Interface:
1. Xlight Panel → **Web Server**
2. Aktiviere HTTP Access
3. Port: 8080 (oder custom)

---

## 🔍 Troubleshooting

### Problem: "Connection refused"

**Lösung:**
```bash
# Prüfe ob Xlight läuft
tasklist | findstr Xlight

# Prüfe Port 21
netstat -an | findstr :21

# Teste Verbindung
telnet your-server-ip 21
```

### Problem: "530 Login authentication failed"

**Ursachen:**
- ❌ Falscher Benutzername/Passwort
- ❌ Benutzer nicht aktiviert in Xlight
- ❌ IP-Beschränkungen

**Lösung:**
1. Xlight Panel → **Users** → **Weltenbibliothek**
2. Prüfe **Password:** Jolene2305
3. Prüfe **Status:** Enabled
4. Prüfe **IP Access:** Allow all (oder deine IP)

### Problem: "550 Permission denied"

**Lösung:**
1. Xlight Panel → **Users** → **Weltenbibliothek**
2. Setze **All Permissions** (Read, Write, Delete, etc.)
3. Prüfe Windows-Ordner-Berechtigungen:
   - Rechtsklick auf `C:\ftp-data\weltenbibliothek`
   - **Properties** → **Security**
   - Füge Benutzer hinzu mit **Full Control**

### Problem: Script läuft, aber nichts wird hochgeladen

**Prüfe:**
```bash
# Aktiviere Debug-Modus
cd scripts
python3 telegram_to_ftp_sync.py --verbose
```

**Logs prüfen:**
```bash
tail -f sync.log
```

---

## 📱 Integration in Flutter App

Nach erfolgreichem Setup kannst du Medien in Flutter laden:

```dart
import 'package:flutter/material.dart';
import 'services/ftp_media_service.dart';

// Video laden
String videoUrl = FTPMediaService().getVideoUrl('video1.mp4');

// In Video Player verwenden
VideoPlayerController controller = VideoPlayerController.network(videoUrl);
```

---

## 🎉 Fertig!

Dein Telegram → Xlight FTP Sync läuft jetzt!

**Next Steps:**
1. Teste mit paar Testdateien
2. Aktiviere Cron-Job für automatischen Sync
3. Integriere in Flutter App
4. Optional: Richte HTTPS/FTPS ein für Sicherheit

Bei Problemen: Prüfe `sync.log` für Details!
