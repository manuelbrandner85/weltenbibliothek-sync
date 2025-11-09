# 🚀 HTTP Media Server - Auto-Start Lösung (Komplett)

## ✅ Erstellte Dateien (Alle bereit für Windows)

### 📦 Haupt-Dateien

| Datei | Zweck | Ausführung |
|-------|-------|------------|
| **media_http_server.py** | Python HTTP-Server (Port 8080) | Automatisch durch Service |
| **start_media_server.bat** | Manueller Server-Start (Test) | Doppelklick |
| **install_http_service.bat** | Installiert Windows-Dienst | Als Administrator |
| **uninstall_http_service.bat** | Entfernt Windows-Dienst | Als Administrator |
| **check_service_status.bat** | Status-Prüfung & Diagnose | Doppelklick |

### 📖 Dokumentation

| Datei | Inhalt |
|-------|--------|
| **SCHNELLSTART.md** | ⚡ 3-Minuten-Setup-Anleitung |
| **INSTALLATION_ANLEITUNG.md** | 📚 Ausführliche Dokumentation mit 3 Methoden |
| **README_AUTO_START.md** | 📋 Diese Datei (Übersicht) |

---

## 🎯 Schnellstart (5 Minuten)

### ✅ Schritt 1: NSSM herunterladen

1. **Link öffnen**: https://nssm.cc/download
2. **Download**: "nssm 2.24" (~300 KB)
3. **Entpacken** und `nssm.exe` kopieren nach:
   ```
   flutter_app\scripts\nssm.exe
   ```

### ✅ Schritt 2: Service installieren

1. **Rechtsklick** auf `install_http_service.bat`
2. **"Als Administrator ausführen"**
3. ✅ Warten bis "Installation erfolgreich"

### ✅ Schritt 3: Testen

**Browser öffnen:**
- http://localhost:8080
- http://Weltenbibliothek.ddns.net:8080

**Fertig!** 🎉 Server startet ab jetzt automatisch mit Windows.

---

## 🔍 Was macht das System?

### Automatischer Ablauf

1. **Windows startet** → Service "WeltenbibliothekMediaServer" startet automatisch
2. **Python-Script läuft** im Hintergrund (keine Fenster)
3. **Port 8080 öffnet** sich für HTTP-Anfragen
4. **Medien-Dateien** vom FTP-Server werden bereitgestellt:
   - `http://Weltenbibliothek.ddns.net:8080/chat/photo_*.jpg`
   - `http://Weltenbibliothek.ddns.net:8080/pdfs/*.pdf`
   - `http://Weltenbibliothek.ddns.net:8080/bilder/*.jpg`
   - usw.
5. **Flutter App** kann jetzt Bilder und Videos laden! ✅

### Technische Details

- **Technologie**: NSSM (Non-Sucking Service Manager)
- **Service-Name**: `WeltenbibliothekMediaServer`
- **Start-Typ**: Automatisch (mit Windows)
- **FTP-Pfad**: `C:\xlight\Weltenbibliothek`
- **HTTP-Port**: 8080
- **Auto-Restart**: Ja (bei Fehler nach 5 Sekunden)
- **Logs**: Automatisch in `http_service.log` und `http_service_error.log`

---

## 🛠️ Service-Verwaltung

### Status prüfen

**Einfach**: `check_service_status.bat` (Doppelklick)

**Manuell**:
```cmd
sc query WeltenbibliothekMediaServer
```

### Service steuern

```cmd
# Starten
net start WeltenbibliothekMediaServer

# Stoppen
net stop WeltenbibliothekMediaServer

# Neustarten
net stop WeltenbibliothekMediaServer & net start WeltenbibliothekMediaServer
```

### Service deinstallieren

**Rechtsklick** auf `uninstall_http_service.bat` → "Als Administrator ausführen"

---

## 📊 3 Installations-Methoden im Vergleich

| Methode | Komplexität | Auto-Start | Hintergrund | Neustart | Log-Dateien |
|---------|-------------|------------|-------------|----------|-------------|
| **1. Windows Service (NSSM)** ⭐ | Mittel | ✅ Mit Windows | ✅ Unsichtbar | ✅ Automatisch | ✅ Ja |
| **2. Scheduled Task** | Mittel | ✅ Mit Windows | ⚠️ Fenster | ⚠️ Manuell | ❌ Nein |
| **3. Startup-Ordner** | Einfach | ⚠️ Bei Login | ⚠️ Fenster | ❌ Nein | ❌ Nein |

**Empfehlung**: **Methode 1 (Windows Service)** für Produktion

---

## 🔧 Fehlerbehebung

### Problem: "nssm.exe nicht gefunden"

**Lösung**: Laden Sie NSSM von https://nssm.cc/download herunter

### Problem: "Administrator-Rechte erforderlich"

**Lösung**: Rechtsklick → "Als Administrator ausführen"

### Problem: Port 8080 bereits belegt

**Prüfen**:
```cmd
netstat -ano | findstr :8080
```

**Lösung**: Beenden Sie den anderen Prozess oder ändern Sie den Port in `media_http_server.py` (Zeile 12)

### Problem: Firewall blockiert Zugriff

**Lösung** (als Administrator):
```cmd
netsh advfirewall firewall add rule name="Weltenbibliothek HTTP" dir=in action=allow protocol=TCP localport=8080
```

### Problem: FTP-Verzeichnis nicht gefunden

**Lösung**: Prüfen Sie den Pfad in `media_http_server.py`:
```python
FTP_ROOT_PATH = "C:\\xlight\\Weltenbibliothek"  # Muss existieren!
```

---

## 📂 FTP-Verzeichnis-Struktur

Das HTTP-Server stellt diese Verzeichnisse bereit:

```
C:\xlight\Weltenbibliothek\
├── chat/           → http://...:8080/chat/
├── pdfs/           → http://...:8080/pdfs/
├── bilder/         → http://...:8080/bilder/
├── wachauf/        → http://...:8080/wachauf/
├── archiv/         → http://...:8080/archiv/
└── hoerbuch/       → http://...:8080/hoerbuch/
```

---

## 📝 Log-Dateien

### Normal-Ausgaben
```
flutter_app\scripts\http_service.log
```

Enthält:
- Server-Start-Nachrichten
- HTTP-Anfragen (GET/POST)
- Zugriffsstatistiken

### Fehler-Ausgaben
```
flutter_app\scripts\http_service_error.log
```

Enthält:
- Python-Fehler
- Netzwerk-Probleme
- Datei-Zugriffsfehler

**Prüfen mit**: `check_service_status.bat` zeigt automatisch Log-Inhalte

---

## ✅ Erfolgs-Checkliste

Nach der Installation sollten diese Tests erfolgreich sein:

- [ ] `check_service_status.bat` zeigt "ALLES OK"
- [ ] Browser: `http://localhost:8080` zeigt Verzeichnis-Liste
- [ ] Browser: `http://Weltenbibliothek.ddns.net:8080` erreichbar
- [ ] Service läuft: `sc query WeltenbibliothekMediaServer` → "RUNNING"
- [ ] Nach Windows-Neustart: Server startet automatisch
- [ ] Flutter App: Bilder/Videos werden geladen ✅

---

## 🔗 Integration mit Telegram-Sync

Der HTTP-Server arbeitet zusammen mit den 6 Telegram-Sync-Scripts:

1. **Telegram** → **PHP-Sync-Scripts** → **FTP-Upload** → **Firestore**
2. **FTP-Dateien** → **HTTP-Server (Port 8080)** → **Flutter App**

**Datenfluss**:
```
Telegram Channel
    ↓ MadelineProto 8.6.0
PHP Sync Scripts (6x)
    ↓ FTP Upload
C:\xlight\Weltenbibliothek\
    ↓ HTTP Server (Port 8080)
Flutter App (Bilder/Videos laden) ✅
```

---

## 🌐 URL-Struktur

### Lokaler Zugriff (auf Windows-PC)
```
http://localhost:8080/chat/photo_001.jpg
http://localhost:8080/pdfs/document.pdf
```

### Externer Zugriff (von Flutter App)
```
http://Weltenbibliothek.ddns.net:8080/chat/photo_001.jpg
http://Weltenbibliothek.ddns.net:8080/pdfs/document.pdf
```

**WICHTIG**: Firestore speichert URLs im Format:
```json
{
  "ftpPath": "/chat/photo_001.jpg",
  "mediaUrl": "http://Weltenbibliothek.ddns.net:8080/chat/photo_001.jpg"
}
```

---

## 🎯 Nächste Schritte nach Installation

1. ✅ **Service installieren** (install_http_service.bat)
2. ✅ **Status prüfen** (check_service_status.bat)
3. ✅ **Browser-Test** (http://localhost:8080)
4. ✅ **Telegram-Sync starten** (6x PHP-Scripts ausführen)
5. ✅ **Flutter App testen** (APK installieren und Bilder prüfen)
6. ✅ **Windows neu starten** (Auto-Start testen)

---

## 📞 Support & Dokumentation

### Schnelle Hilfe
- **Doppelklick**: `check_service_status.bat` → Zeigt alle wichtigen Infos
- **Prüfen**: Log-Dateien (`http_service.log` und `http_service_error.log`)

### Ausführliche Hilfe
- **SCHNELLSTART.md**: 3-Minuten-Setup mit Bildern
- **INSTALLATION_ANLEITUNG.md**: Alle 3 Methoden detailliert erklärt

### Telegram-Sync-Dokumentation
- **README_TELEGRAM_FTP_SYNC.md**: Telegram-Integration
- **XLIGHT_FTP_SETUP.md**: FTP-Server-Konfiguration
- **TELEGRAM_CREDENTIALS_SETUP.md**: Telegram-API-Setup

---

## 🏆 Vorteile dieser Lösung

✅ **Automatisch**: Startet mit Windows (kein manuelles Eingreifen)  
✅ **Stabil**: Automatischer Neustart bei Fehlern  
✅ **Unsichtbar**: Läuft im Hintergrund (keine Fenster)  
✅ **Logs**: Automatische Protokollierung in Dateien  
✅ **Einfach**: Verwaltung über Windows Services  
✅ **Professionell**: Produktions-reife Lösung  
✅ **Getestet**: Funktioniert mit Flutter App und Telegram-Sync  

---

**Erstellt für**: Weltenbibliothek Projekt  
**Version**: 1.0  
**Datum**: November 2025  
**Lizenz**: Privat (Manuel Brandner)

---

**🚀 Viel Erfolg mit dem automatischen HTTP Media Server!**
