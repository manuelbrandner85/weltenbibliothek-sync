# 🪟 Windows HTTP-Server Setup für Weltenbibliothek

## 📋 Voraussetzungen

Ihr Windows-Server:
- **Hostname:** Weltenbibliothek.ddns.net
- **FTP-Ordner:** C:\FTP_Media\
- **Benötigter Port:** 8080 (HTTP)

---

## ⚡ SCHNELL-SETUP (5 Minuten)

### Schritt 1: Chat-Ordner erstellen (1 Minute)

**Option A: Windows Explorer**
1. Öffnen Sie `C:\FTP_Media\`
2. Rechtsklick → **Neuer Ordner**
3. Name eingeben: `chat`
4. Enter drücken

**Option B: PowerShell**
```powershell
cd C:\FTP_Media
mkdir chat
```

**Ergebnis:**
```
C:\FTP_Media\
├── audios\
├── images\
├── pdfs\
├── videos\
└── chat\      ← NEU!
```

---

### Schritt 2: Python HTTP-Server starten (1 Minute)

**PowerShell als Administrator öffnen:**
1. Windows-Taste drücken
2. Tippen: `PowerShell`
3. Rechtsklick → **Als Administrator ausführen**

**Befehle eingeben:**
```powershell
cd C:\FTP_Media
python -m http.server 8080
```

**Erwartete Ausgabe:**
```
Serving HTTP on :: port 8080 (http://[::]:8080/) ...
```

✅ **Server läuft!** Lassen Sie dieses Fenster offen.

---

### Schritt 3: Firewall-Regel erstellen (2 Minuten)

**Option A: PowerShell (schnell)**
```powershell
New-NetFirewallRule -DisplayName "HTTP Server Port 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

**Option B: Windows Firewall GUI**
1. Windows-Taste → `Firewall`
2. **Erweiterte Einstellungen** öffnen
3. Links: **Eingehende Regeln**
4. Rechts: **Neue Regel...**
5. Regeltyp: **Port** → Weiter
6. Protokoll: **TCP** → Port: `8080` → Weiter
7. Aktion: **Verbindung zulassen** → Weiter
8. Profile: **Alle** aktivieren → Weiter
9. Name: `HTTP Server Port 8080` → Fertig stellen

---

### Schritt 4: Test (1 Minute)

**Lokal testen (auf dem Windows-Server):**
```
Browser öffnen: http://localhost:8080/chat/
```

**Erwartung:** Browser zeigt Ordner-Listing oder "403 Forbidden" (beides OK!)

**Extern testen (von einem anderen Gerät):**
```
Browser öffnen: http://Weltenbibliothek.ddns.net:8080/chat/
```

**Erwartung:** Gleiche Anzeige wie lokal

---

## 🔧 Alternative: IIS (Internet Information Services)

Falls Sie einen professionellen HTTP-Server bevorzugen:

### IIS Installation

**PowerShell als Administrator:**
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
```

### IIS Konfiguration

1. **IIS Manager öffnen:**
   - Windows-Taste → `inetmgr`

2. **Neue Website erstellen:**
   - Rechtsklick auf **Sites** → **Website hinzufügen**
   - **Site-Name:** Weltenbibliothek HTTP
   - **Physischer Pfad:** `C:\FTP_Media`
   - **Binding:**
     - Typ: **http**
     - IP-Adresse: **Alle nicht zugewiesenen**
     - Port: **8080**
   - **OK** klicken

3. **Directory Browsing aktivieren:**
   - Website auswählen
   - **Directory Browsing** doppelklicken
   - **Aktivieren** klicken (rechte Seite)

4. **CORS Headers hinzufügen (optional):**
   - **HTTP-Antwortheader** öffnen
   - **Hinzufügen** klicken
   - Name: `Access-Control-Allow-Origin`
   - Wert: `*`

---

## 🚀 Als Windows-Dienst einrichten (Optional)

Damit der HTTP-Server automatisch beim Systemstart läuft:

### Python HTTP-Server als Dienst

**NSSM (Non-Sucking Service Manager) verwenden:**

1. **NSSM herunterladen:**
   - https://nssm.cc/download
   - Zip entpacken nach `C:\nssm\`

2. **Dienst erstellen:**
```powershell
cd C:\nssm\win64
.\nssm.exe install WeltenbibliothekHTTP python -m http.server 8080
.\nssm.exe set WeltenbibliothekHTTP AppDirectory C:\FTP_Media
.\nssm.exe set WeltenbibliothekHTTP DisplayName "Weltenbibliothek HTTP Server"
.\nssm.exe set WeltenbibliothekHTTP Description "HTTP-Server für Weltenbibliothek Media-Dateien"
.\nssm.exe set WeltenbibliothekHTTP Start SERVICE_AUTO_START
.\nssm.exe start WeltenbibliothekHTTP
```

3. **Dienst-Status prüfen:**
```powershell
Get-Service WeltenbibliothekHTTP
```

**Dienst-Management:**
```powershell
# Starten
Start-Service WeltenbibliothekHTTP

# Stoppen
Stop-Service WeltenbibliothekHTTP

# Neustart
Restart-Service WeltenbibliothekHTTP

# Deinstallieren
.\nssm.exe remove WeltenbibliothekHTTP confirm
```

---

## 🐛 Fehlerbehebung

### Problem: "python: command not found"

**Lösung:** Python installieren
```
https://www.python.org/downloads/
```
Bei Installation: **"Add Python to PATH"** aktivieren!

### Problem: "Port 8080 already in use"

**Lösung 1:** Anderen Port verwenden
```powershell
python -m http.server 8081
```

**Lösung 2:** Prozess beenden, der Port 8080 blockiert
```powershell
# Prozess finden
netstat -ano | findstr :8080

# Prozess beenden (PID ersetzen)
taskkill /PID <PID> /F
```

### Problem: HTTP-Server von extern nicht erreichbar

**Checkliste:**
1. ✅ Firewall-Regel für Port 8080?
2. ✅ Router Port-Forwarding konfiguriert?
3. ✅ DynDNS-Dienst läuft (für ddns.net)?
4. ✅ Server-Firewall erlaubt eingehende Verbindungen?

**Router Port-Forwarding:**
```
Externe Port: 8080
Interne IP: <Windows-Server-IP>
Interne Port: 8080
Protokoll: TCP
```

### Problem: 403 Forbidden

Das ist **NORMAL** wenn der Ordner leer ist!

**Test mit Datei:**
1. Erstellen Sie: `C:\FTP_Media\chat\test.txt`
2. Inhalt: "Test-Datei"
3. Browser: `http://localhost:8080/chat/test.txt`
4. Sollte zeigen: "Test-Datei"

---

## ✅ Verifizierung

Nach dem Setup sollten folgende Tests erfolgreich sein:

### Test 1: Lokal (auf Windows-Server)
```
http://localhost:8080/chat/
→ Sollte Ordner-Listing zeigen oder 403
```

### Test 2: LAN (von anderem Gerät im Netzwerk)
```
http://<Windows-Server-IP>:8080/chat/
→ Gleiche Anzeige wie Test 1
```

### Test 3: Extern (von Internet)
```
http://Weltenbibliothek.ddns.net:8080/chat/
→ Gleiche Anzeige wie Test 1
```

### Test 4: Vollständiger FTP-Test (von Sandbox)
```bash
cd /home/user/flutter_app/scripts
php test_ftp_chat_upload.php
```

**Erwartete Ausgabe:**
```
✅ FTP-Verbindung:     Erfolgreich
✅ FTP-Login:          Erfolgreich
✅ Ordner /chat/:      Existiert
✅ FTP-Upload:         Funktioniert
✅ HTTP-Zugriff:       Funktioniert
✅ FTP-Delete:         Funktioniert
```

---

## 📊 Ordner-Struktur nach Setup

```
C:\FTP_Media\                    ← HTTP-Server Root (Port 8080)
├── audios\                      ← http://...ddns.net:8080/audios/
├── images\                      ← http://...ddns.net:8080/images/
├── pdfs\                        ← http://...ddns.net:8080/pdfs/
├── videos\                      ← http://...ddns.net:8080/videos/
└── chat\                        ← http://...ddns.net:8080/chat/
    ├── image_1234567890.jpg     ← Chat-Bilder (Telegram ↔ App)
    ├── video_1234567891.mp4     ← Chat-Videos
    └── audio_1234567892.mp3     ← Chat-Audio
```

---

## 🎯 Zusammenfassung

**Minimales Setup (3 Schritte):**
1. ✅ Ordner erstellen: `C:\FTP_Media\chat\`
2. ✅ HTTP-Server starten: `python -m http.server 8080`
3. ✅ Firewall-Regel: Port 8080 öffnen

**Zeitaufwand:** ~5 Minuten

**Dann funktioniert:**
- ✅ Telegram → App Chat-Sync mit Medien
- ✅ App → Telegram Chat-Sync mit Medien
- ✅ Auto-Delete nach 6 Stunden
- ✅ HTTP-Zugriff auf Chat-Medien

---

**Letzte Aktualisierung:** 2025-11-08  
**Version:** 1.0
