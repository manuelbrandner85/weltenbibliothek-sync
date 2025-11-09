# ⚡ Weltenbibliothek HTTP Media Server - Schnellstart

## 🎯 Ziel

Den HTTP Media Server so einrichten, dass er **automatisch mit Windows startet** und Medien-Dateien vom FTP-Server über HTTP bereitstellt.

---

## 📋 3-Minuten-Setup (Empfohlene Methode)

### Schritt 1: NSSM herunterladen (einmalig)

1. **Öffnen Sie**: https://nssm.cc/download
2. **Laden Sie herunter**: "nssm 2.24" (ZIP-Datei, ~300 KB)
3. **Entpacken Sie** die ZIP-Datei
4. **Kopieren Sie** `win64\nssm.exe` in dieses Verzeichnis:
   ```
   flutter_app\scripts\
   ```

### Schritt 2: Service installieren

1. **Rechtsklick** auf `install_http_service.bat`
2. **Wählen Sie**: "Als Administrator ausführen"
3. **Warten Sie** ca. 10 Sekunden bis "Installation erfolgreich" erscheint

### Schritt 3: Testen

**Im Browser öffnen:**
- `http://localhost:8080`
- `http://Weltenbibliothek.ddns.net:8080`

**Fertig!** ✅ Der Server läuft jetzt automatisch mit Windows.

---

## 🔍 Status prüfen

**Doppelklick auf**: `check_service_status.bat`

Das Script zeigt:
- ✅ Service-Status (läuft / gestoppt)
- ✅ Port 8080 Belegung
- ✅ HTTP-Erreichbarkeit
- ✅ Log-Dateien
- ✅ FTP-Verzeichnis
- ✅ Zusammenfassung

---

## 🛠️ Wichtige Befehle

### Service verwalten

```cmd
# Service starten
net start WeltenbibliothekMediaServer

# Service stoppen
net stop WeltenbibliothekMediaServer

# Service neustarten
net stop WeltenbibliothekMediaServer & net start WeltenbibliothekMediaServer

# Status prüfen
sc query WeltenbibliothekMediaServer
```

### Service deinstallieren

**Rechtsklick auf**: `uninstall_http_service.bat` → "Als Administrator ausführen"

---

## 📂 Dateien-Übersicht

| Datei | Zweck |
|-------|-------|
| `media_http_server.py` | HTTP-Server (Python-Script) |
| `start_media_server.bat` | Manueller Server-Start (für Tests) |
| `install_http_service.bat` | Service-Installation (als Administrator) |
| `uninstall_http_service.bat` | Service-Deinstallation (als Administrator) |
| `check_service_status.bat` | Status-Prüfung (Doppelklick) |
| `nssm.exe` | Service-Manager (muss heruntergeladen werden) |
| `INSTALLATION_ANLEITUNG.md` | Ausführliche Dokumentation |
| `SCHNELLSTART.md` | Diese Datei |

---

## 🔧 Fehlerbehebung

### Problem: "nssm.exe nicht gefunden"

**Lösung**: Laden Sie NSSM herunter (siehe Schritt 1 oben)

### Problem: "Administrator-Rechte erforderlich"

**Lösung**: Rechtsklick → "Als Administrator ausführen"

### Problem: Service startet nicht

**Lösung**:
1. Öffnen Sie `check_service_status.bat`
2. Prüfen Sie `http_service_error.log`
3. Stellen Sie sicher, dass Python installiert ist: `python --version`

### Problem: Port 8080 bereits belegt

**Lösung**:
1. Prüfen Sie welcher Prozess Port 8080 nutzt:
   ```cmd
   netstat -ano | findstr :8080
   ```
2. Beenden Sie den Prozess oder ändern Sie den Port in `media_http_server.py`

### Problem: Firewall blockiert Zugriff

**Lösung** (als Administrator):
```cmd
netsh advfirewall firewall add rule name="Weltenbibliothek HTTP" dir=in action=allow protocol=TCP localport=8080
```

---

## ✅ Was passiert nach der Installation?

1. **Windows startet** → Service startet automatisch im Hintergrund
2. **HTTP Server läuft** auf Port 8080
3. **Medien-Dateien** vom FTP-Server sind unter verfügbar:
   - `http://Weltenbibliothek.ddns.net:8080/chat/photo_001.jpg`
   - `http://Weltenbibliothek.ddns.net:8080/pdfs/document.pdf`
   - usw.
4. **Flutter App** kann Bilder/Videos laden
5. **Bei Fehler**: Service startet automatisch neu (nach 5 Sekunden)

---

## 📊 Logs

**Normal-Ausgaben:**
```
flutter_app\scripts\http_service.log
```

**Fehler:**
```
flutter_app\scripts\http_service_error.log
```

**Log-Größe**: Wird automatisch bei 10 MB rotiert

---

## 🎯 Alternative: Manueller Start (zum Testen)

Wenn Sie den Service **nicht automatisch** starten wollen:

**Doppelklick auf**: `start_media_server.bat`

**Vorteil**: Konsolenfenster mit Live-Logs  
**Nachteil**: Muss nach jedem Windows-Neustart neu gestartet werden

---

## 📞 Hilfe

Bei weiteren Fragen:
- Öffnen Sie `INSTALLATION_ANLEITUNG.md` für ausführliche Dokumentation
- Prüfen Sie die Log-Dateien
- Führen Sie `check_service_status.bat` aus

---

**Viel Erfolg! 🚀**
