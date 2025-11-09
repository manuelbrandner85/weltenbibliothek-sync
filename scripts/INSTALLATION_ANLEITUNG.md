# 🚀 Weltenbibliothek HTTP Media Server - Auto-Start Installation

## Übersicht

Diese Anleitung zeigt, wie Sie den HTTP Media Server als Windows-Dienst einrichten, der **automatisch mit Windows startet**.

## 📋 Voraussetzungen

- ✅ Windows 10/11 oder Windows Server
- ✅ Python 3.x installiert (bereits vorhanden)
- ✅ Administrator-Rechte
- ✅ NSSM (Non-Sucking Service Manager) - wird in Anleitung erklärt

## 🎯 Methode 1: Windows Service mit NSSM (EMPFOHLEN)

### Vorteile
- ✅ Automatischer Start mit Windows
- ✅ Läuft im Hintergrund (kein Fenster)
- ✅ Automatischer Neustart bei Fehler
- ✅ Integrierte Log-Dateien
- ✅ Einfache Verwaltung über Windows Services

### Installations-Schritte

#### Schritt 1: NSSM herunterladen

**Option A: Manueller Download (empfohlen)**
1. Öffnen Sie: https://nssm.cc/download
2. Laden Sie **"nssm 2.24"** herunter
3. Entpacken Sie die ZIP-Datei
4. Kopieren Sie `win64\nssm.exe` nach:
   ```
   C:\Users\[IhrBenutzer]\flutter_app\scripts\
   ```

**Option B: PowerShell-Download (erfordert Internet)**
```powershell
# Als Administrator ausführen
cd C:\Users\[IhrBenutzer]\flutter_app\scripts\
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "nssm.zip"
Expand-Archive -Path "nssm.zip" -DestinationPath "."
copy "nssm-2.24\win64\nssm.exe" "nssm.exe"
```

#### Schritt 2: Service installieren

1. **Rechtsklick** auf `install_http_service.bat`
2. Wählen Sie **"Als Administrator ausführen"**
3. Das Script führt folgende Schritte aus:
   - ✅ Prüft Administrator-Rechte
   - ✅ Prüft Python-Installation
   - ✅ Ermittelt Python- und Script-Pfade
   - ✅ Installiert Windows-Dienst "WeltenbibliothekMediaServer"
   - ✅ Konfiguriert automatischen Start
   - ✅ Startet den Dienst

#### Schritt 3: Überprüfung

Nach erfolgreicher Installation:

**A) Browser-Test:**
- Öffnen Sie: `http://localhost:8080`
- Oder: `http://Weltenbibliothek.ddns.net:8080`

**B) Windows Services prüfen:**
```cmd
# Service-Status anzeigen
sc query WeltenbibliothekMediaServer

# Oder öffnen Sie: services.msc
# Suchen Sie nach "WeltenbibliothekMediaServer"
```

**C) Log-Dateien prüfen:**
```
C:\Users\[IhrBenutzer]\flutter_app\scripts\http_service.log
C:\Users\[IhrBenutzer]\flutter_app\scripts\http_service_error.log
```

### Service-Verwaltung

**Service stoppen:**
```cmd
net stop WeltenbibliothekMediaServer
```

**Service starten:**
```cmd
net start WeltenbibliothekMediaServer
```

**Service neustarten:**
```cmd
net stop WeltenbibliothekMediaServer & net start WeltenbibliothekMediaServer
```

**Service-Status prüfen:**
```cmd
sc query WeltenbibliothekMediaServer
```

**Service deinstallieren:**
- Rechtsklick auf `uninstall_http_service.bat` → "Als Administrator ausführen"
- Oder manuell:
  ```cmd
  nssm remove WeltenbibliothekMediaServer confirm
  ```

## 🎯 Methode 2: Windows Scheduled Task (Alternative)

### Vorteile
- ✅ Keine zusätzliche Software erforderlich
- ✅ Automatischer Start mit Windows
- ✅ Einfache Konfiguration

### Nachteile
- ⚠️ Läuft im sichtbaren Fenster (kann minimiert werden)
- ⚠️ Kein automatischer Neustart bei Fehler

### Installations-Schritte

#### Option A: Grafische Oberfläche (Aufgabenplanung)

1. **Windows-Taste + R** → `taskschd.msc` → Enter

2. **Rechte Seite**: "Aufgabe erstellen..." (nicht "Einfache Aufgabe"!)

3. **Reiter "Allgemein":**
   - Name: `Weltenbibliothek HTTP Media Server`
   - Beschreibung: `Startet HTTP Server für Medien-Dateien`
   - ☑️ "Mit höchsten Privilegien ausführen"
   - Benutzer: Ihr Windows-Benutzerkonto

4. **Reiter "Trigger":**
   - **Neue Trigger...** → "Bei Anmeldung"
   - Oder: **Neue Trigger...** → "Beim Start"
   - Verzögerung: 30 Sekunden (falls FTP-Server zuerst starten muss)

5. **Reiter "Aktionen":**
   - **Neue Aktion...**
   - Aktion: "Programm starten"
   - Programm: `python`
   - Argumente: `media_http_server.py`
   - Starten in: `C:\Users\[IhrBenutzer]\flutter_app\scripts\`

6. **Reiter "Bedingungen":**
   - ☐ Aufgabe nur starten, falls Computer im Netzbetrieb (deaktivieren)

7. **Reiter "Einstellungen":**
   - ☑️ Bei Fehler Aufgabe neu starten
   - Versuch wird wiederholt: Alle 1 Minute
   - Bis zu: 3 Mal

8. **OK** → ggf. Administrator-Passwort eingeben

#### Option B: PowerShell-Befehl

```powershell
# Als Administrator ausführen
$action = New-ScheduledTaskAction -Execute "python" -Argument "media_http_server.py" -WorkingDirectory "C:\Users\[IhrBenutzer]\flutter_app\scripts\"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName "WeltenbibliothekMediaServer" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Weltenbibliothek HTTP Media Server für FTP-Medien"
```

### Task-Verwaltung

**Task manuell starten:**
```powershell
Start-ScheduledTask -TaskName "WeltenbibliothekMediaServer"
```

**Task stoppen:**
```powershell
Stop-ScheduledTask -TaskName "WeltenbibliothekMediaServer"
```

**Task löschen:**
```powershell
Unregister-ScheduledTask -TaskName "WeltenbibliothekMediaServer" -Confirm:$false
```

## 🎯 Methode 3: Startup-Ordner (Einfachste Methode)

### Vorteile
- ✅ Sehr einfach einzurichten
- ✅ Keine Administrator-Rechte erforderlich

### Nachteile
- ⚠️ Startet nur bei Benutzer-Anmeldung
- ⚠️ Sichtbares Konsolenfenster
- ⚠️ Kein automatischer Neustart

### Installations-Schritte

1. **Öffnen Sie den Startup-Ordner:**
   - **Windows-Taste + R** → `shell:startup` → Enter
   - Oder öffnen Sie:
     ```
     C:\Users\[IhrBenutzer]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\
     ```

2. **Erstellen Sie eine Verknüpfung:**
   - Rechtsklick → "Neu" → "Verknüpfung"
   - Ziel eingeben:
     ```
     C:\Users\[IhrBenutzer]\flutter_app\scripts\start_media_server.bat
     ```
   - Name: `Weltenbibliothek Media Server`

3. **Optional - Minimiert starten:**
   - Rechtsklick auf Verknüpfung → "Eigenschaften"
   - "Ausführen": "Minimiert"
   - OK

4. **Fertig!** Der Server startet beim nächsten Windows-Login automatisch.

## 🔍 Fehlerbehebung

### Problem: Service startet nicht

**Lösung 1: Python-Pfad prüfen**
```cmd
where python
python --version
```

**Lösung 2: Log-Dateien prüfen**
```
C:\Users\[IhrBenutzer]\flutter_app\scripts\http_service_error.log
```

**Lösung 3: Port 8080 bereits belegt**
```cmd
netstat -ano | findstr :8080
```

### Problem: Kein Zugriff von außen

**Lösung: Windows Firewall konfigurieren**
```cmd
# Als Administrator ausführen
netsh advfirewall firewall add rule name="Weltenbibliothek HTTP Server" dir=in action=allow protocol=TCP localport=8080
```

### Problem: FTP-Dateien nicht erreichbar

**Lösung: FTP-Pfad in media_http_server.py prüfen**
```python
FTP_ROOT_PATH = "C:\\xlight\\Weltenbibliothek"  # Muss korrekt sein!
```

## 📊 Vergleich der Methoden

| Methode | Komplexität | Auto-Start | Hintergrund | Neustart | Empfohlen |
|---------|-------------|------------|-------------|----------|-----------|
| **Windows Service (NSSM)** | Mittel | ✅ Windows | ✅ Ja | ✅ Automatisch | ⭐⭐⭐⭐⭐ |
| **Scheduled Task** | Mittel | ✅ Windows | ⚠️ Fenster | ⚠️ Manuell | ⭐⭐⭐⭐ |
| **Startup-Ordner** | Einfach | ⚠️ Login | ⚠️ Fenster | ❌ Nein | ⭐⭐⭐ |

## 🎯 Empfehlung

**Für Produktionssysteme**: Verwenden Sie **Methode 1 (Windows Service mit NSSM)**

**Vorteile:**
- Startet automatisch mit Windows (vor Benutzer-Login)
- Läuft stabil im Hintergrund
- Automatischer Neustart bei Abstürzen
- Professionelle Log-Verwaltung
- Einfache Verwaltung über Windows Services

## 📞 Support

Bei Problemen:
1. Prüfen Sie die Log-Dateien
2. Testen Sie den Server manuell: `start_media_server.bat`
3. Prüfen Sie die Firewall-Einstellungen
4. Verifizieren Sie den FTP-Pfad in `media_http_server.py`

## ✅ Erfolgs-Checkliste

Nach der Installation sollten folgende Tests erfolgreich sein:

- [ ] Browser-Test: `http://localhost:8080` zeigt Verzeichnisliste
- [ ] Externer Test: `http://Weltenbibliothek.ddns.net:8080` erreichbar
- [ ] Service läuft: `sc query WeltenbibliothekMediaServer` zeigt "RUNNING"
- [ ] Nach Windows-Neustart: Server startet automatisch
- [ ] Flutter App: Bilder werden korrekt geladen

---

**Erstellt für: Weltenbibliothek Projekt**  
**Datum: 2025**  
**Version: 1.0**
