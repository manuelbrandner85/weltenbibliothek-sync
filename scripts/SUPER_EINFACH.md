# 🎯 HTTP Server Auto-Start - SUPER EINFACH!

## Was Sie brauchen: NUR 3 KLICKS!

---

## 📥 SCHRITT 1: Diese 6 Dateien herunterladen

**Klicken Sie auf jede Datei und laden Sie sie herunter:**

### ✅ Datei 1: media_http_server.py
```
Speichern unter: C:\Users\[IhrName]\flutter_app\scripts\media_http_server.py
```
**Was macht sie?** Der HTTP-Server (das Hauptprogramm)

---

### ✅ Datei 2: start_media_server.bat
```
Speichern unter: C:\Users\[IhrName]\flutter_app\scripts\start_media_server.bat
```
**Was macht sie?** Zum manuellen Testen (falls Sie testen wollen)

---

### ✅ Datei 3: install_http_service.bat
```
Speichern unter: C:\Users\[IhrName]\flutter_app\scripts\install_http_service.bat
```
**Was macht sie?** Installiert den Auto-Start ⭐ WICHTIG!

---

### ✅ Datei 4: uninstall_http_service.bat
```
Speichern unter: C:\Users\[IhrName]\flutter_app\scripts\uninstall_http_service.bat
```
**Was macht sie?** Falls Sie es wieder entfernen wollen

---

### ✅ Datei 5: check_service_status.bat
```
Speichern unter: C:\Users\[IhrName]\flutter_app\scripts\check_service_status.bat
```
**Was macht sie?** Prüft ob alles funktioniert

---

### ✅ Datei 6: NSSM herunterladen

**WICHTIG**: Diese Datei müssen Sie von einer anderen Website laden!

1. **Öffnen Sie**: https://nssm.cc/download
2. **Klicken Sie**: "Download nssm 2.24"
3. **Warten Sie**: Download fertig (~300 KB)
4. **Rechtsklick** auf die ZIP-Datei → "Alle extrahieren..."
5. **Öffnen Sie**: `nssm-2.24` → `win64` Ordner
6. **Kopieren Sie**: `nssm.exe`
7. **Speichern unter**: `C:\Users\[IhrName]\flutter_app\scripts\nssm.exe`

---

## ⚡ SCHRITT 2: Service installieren (1 KLICK!)

1. **Gehen Sie zu**: `C:\Users\[IhrName]\flutter_app\scripts\`
2. **Rechtsklick** auf: `install_http_service.bat`
3. **Klicken Sie**: "Als Administrator ausführen"
4. **FERTIG!** ✅

---

## 🎉 SCHRITT 3: Testen (1 KLICK!)

**Im Browser öffnen**: http://localhost:8080

**Sie sollten sehen**:
```
Index of /
- chat/
- pdfs/
- bilder/
- wachauf/
- archiv/
- hoerbuch/
```

✅ **PERFEKT!** Alles funktioniert!

---

## 🚀 DAS WAR'S!

**Ab jetzt**:
- ✅ Server startet **automatisch** mit Windows
- ✅ **Kein** manuelles Starten mehr nötig
- ✅ Flutter App kann Bilder und Videos laden

---

## ❓ Probleme?

### Problem 1: "Administrator-Rechte erforderlich"
**Sie haben falsch geklickt!**

❌ **Falsch**: Doppelklick auf install_http_service.bat  
✅ **Richtig**: **Rechtsklick** → "Als Administrator ausführen"

---

### Problem 2: "nssm.exe nicht gefunden"
**Sie haben Schritt 1 Datei 6 vergessen!**

→ Laden Sie NSSM herunter (siehe oben Datei 6)

---

### Problem 3: "Python nicht installiert"
**Python fehlt auf Ihrem PC!**

1. Öffnen Sie: https://www.python.org/downloads/
2. Klicken Sie: "Download Python"
3. **WICHTIG**: ☑️ Haken bei "Add Python to PATH"
4. Klicken Sie: "Install Now"
5. Windows **neu starten**
6. Dann nochmal Schritt 2 machen

---

### Problem 4: Browser zeigt nichts
**Prüfen Sie den Status!**

1. **Doppelklick** auf: `check_service_status.bat`
2. Lesen Sie was da steht
3. Wenn "Service läuft" → Alles OK!
4. Wenn "Service NICHT installiert" → Schritt 2 nochmal machen

---

## 🔧 Nützliche Befehle

### Status prüfen
**Doppelklick**: `check_service_status.bat`

### Service stoppen
1. Windows-Taste + R
2. Eingeben: `net stop WeltenbibliothekMediaServer`
3. Enter

### Service starten
1. Windows-Taste + R
2. Eingeben: `net start WeltenbibliothekMediaServer`
3. Enter

### Service komplett entfernen
**Rechtsklick** auf `uninstall_http_service.bat` → "Als Administrator ausführen"

---

## ✅ Checkliste (Haken Sie ab!)

- [ ] Ordner erstellt: `C:\Users\[IhrName]\flutter_app\scripts\`
- [ ] 5 Dateien heruntergeladen (media_http_server.py, usw.)
- [ ] NSSM heruntergeladen (nssm.exe)
- [ ] install_http_service.bat als Administrator ausgeführt
- [ ] Browser-Test erfolgreich: http://localhost:8080
- [ ] Windows neu gestartet (Server startet automatisch)
- [ ] Flutter App zeigt Bilder

---

## 📱 Flutter App testen

1. **Öffnen Sie** die Weltenbibliothek App
2. **Gehen Sie** zur Telegram-Seite
3. **Warten Sie** 2-3 Sekunden
4. **Bilder sollten** jetzt erscheinen! 🎉

---

## 🎯 Wichtig zu wissen

**Nach der Installation passiert**:
- ✅ Server läuft **automatisch** (kein Fenster)
- ✅ Startet **automatisch** bei Windows-Start
- ✅ Läuft auf Port 8080
- ✅ Kein manuelles Starten mehr nötig

**Das war's!** 🚀

Bei Problemen: Lesen Sie die Lösungen oben unter "❓ Probleme"
