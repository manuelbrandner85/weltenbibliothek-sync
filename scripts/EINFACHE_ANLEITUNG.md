# 🚀 HTTP Media Server - Ganz einfach installieren

## Was macht das?

Der HTTP-Server stellt Ihre Telegram-Bilder und -Videos über das Internet bereit, damit die Flutter App sie anzeigen kann.

Nach der Installation startet der Server **automatisch** mit Windows - Sie müssen nichts mehr manuell starten!

---

## ⚡ Installation in 6 einfachen Schritten

### Schritt 1: Ordner erstellen

1. Öffnen Sie den **Windows Explorer**
2. Gehen Sie zu: `C:\Users\[IhrName]\` (ersetzen Sie [IhrName] mit Ihrem Windows-Benutzernamen)
3. Erstellen Sie einen neuen Ordner: `flutter_app`
4. Öffnen Sie diesen Ordner
5. Erstellen Sie darin einen Ordner: `scripts`

**Fertiger Pfad**: `C:\Users\[IhrName]\flutter_app\scripts\`

---

### Schritt 2: Dateien herunterladen

Laden Sie diese **5 Dateien** von der GenSpark-Sandbox herunter:

**Von**: `/home/user/flutter_app/scripts/`

**Zu**: `C:\Users\[IhrName]\flutter_app\scripts\`

**Dateien**:
1. `media_http_server.py`
2. `start_media_server.bat`
3. `install_http_service.bat`
4. `uninstall_http_service.bat`
5. `check_service_status.bat`

💡 **Tipp**: Markieren Sie alle 5 Dateien und kopieren Sie sie auf einmal!

---

### Schritt 3: NSSM herunterladen

**NSSM** ist ein kleines Programm, das den Server als Windows-Dienst installiert.

1. **Öffnen Sie** im Browser: https://nssm.cc/download
2. **Klicken Sie** auf: "Download nssm 2.24"
3. **Warten Sie** bis `nssm-2.24.zip` heruntergeladen ist (~300 KB)
4. **Rechtsklick** auf die ZIP-Datei → "Alle extrahieren..."
5. **Öffnen Sie** den entpackten Ordner `nssm-2.24`
6. **Öffnen Sie** den Ordner `win64`
7. **Kopieren Sie** die Datei `nssm.exe`
8. **Fügen Sie ein** in: `C:\Users\[IhrName]\flutter_app\scripts\`

✅ **Prüfen**: Der Ordner sollte jetzt 6 Dateien enthalten (5 + nssm.exe)

---

### Schritt 4: Service installieren

1. **Öffnen Sie** den Ordner: `C:\Users\[IhrName]\flutter_app\scripts\`
2. **Suchen Sie** die Datei: `install_http_service.bat`
3. **Rechtsklick** auf die Datei
4. **Wählen Sie**: "Als Administrator ausführen"
5. **Warten Sie** ca. 10-15 Sekunden
6. **Lesen Sie** die Meldungen im schwarzen Fenster
7. **Fertig** wenn steht: "✅ Installation erfolgreich abgeschlossen!"

💡 **Wenn es nicht klappt**: Lesen Sie die Fehlermeldung und springen Sie zu "Hilfe bei Problemen" unten

---

### Schritt 5: Prüfen ob es funktioniert

1. **Doppelklick** auf: `check_service_status.bat`
2. **Lesen Sie** die Ausgabe im schwarzen Fenster

✅ **Gut - wenn Sie sehen**:
- ✅ Service läuft
- ✅ Port 8080 ist belegt
- ✅ Server antwortet
- ✅ ALLES OK

❌ **Problem - wenn Sie sehen**:
- ❌ Service ist NICHT installiert
- ❌ Port 8080 ist FREI
- Springen Sie zu "Hilfe bei Problemen" unten

---

### Schritt 6: Im Browser testen

1. **Öffnen Sie** Ihren Browser (Chrome, Firefox, Edge...)
2. **Geben Sie ein**: `http://localhost:8080`
3. **Drücken Sie** Enter

✅ **Perfekt - wenn Sie sehen**:
```
Index of /
- chat/
- pdfs/
- bilder/
- wachauf/
- archiv/
- hoerbuch/
```

❌ **Problem - wenn**:
- "Diese Seite kann nicht angezeigt werden"
- Springen Sie zu "Hilfe bei Problemen" unten

---

## 🎉 Fertig!

**Was passiert jetzt?**
- ✅ Der HTTP-Server läuft auf Port 8080
- ✅ Er startet automatisch mit Windows
- ✅ Ihre Flutter App kann jetzt Bilder und Videos laden
- ✅ Sie müssen **nie wieder** etwas manuell starten!

**Testen Sie die Flutter App**:
- Öffnen Sie die Weltenbibliothek App auf Ihrem Android-Handy
- Gehen Sie zur Telegram-Seite
- Bilder und Videos sollten jetzt angezeigt werden!

---

## ❓ Hilfe bei Problemen

### Problem 1: "nssm.exe nicht gefunden"

**Fehler**: Beim Ausführen von `install_http_service.bat` kommt: "❌ FEHLER: NSSM nicht gefunden"

**Lösung**:
1. Haben Sie Schritt 3 gemacht?
2. Liegt die Datei `nssm.exe` wirklich in `C:\Users\[IhrName]\flutter_app\scripts\`?
3. Wenn nein → Wiederholen Sie Schritt 3

---

### Problem 2: "Administrator-Rechte erforderlich"

**Fehler**: Beim Ausführen kommt: "❌ FEHLER: Administrator-Rechte erforderlich!"

**Lösung**:
1. Sie haben die Datei mit **Doppelklick** geöffnet
2. Das reicht **nicht**!
3. Sie müssen **Rechtsklick** → "Als Administrator ausführen" machen

---

### Problem 3: "Python ist nicht installiert"

**Fehler**: "❌ FEHLER: Python ist nicht installiert!"

**Lösung**:
1. Öffnen Sie: https://www.python.org/downloads/
2. Klicken Sie: "Download Python" (neueste Version)
3. **WICHTIG beim Installieren**:
   - ☑️ Haken bei "Add Python to PATH"
   - Dann auf "Install Now" klicken
4. Nach Installation: Windows **neu starten**
5. Dann Schritt 4 wiederholen

---

### Problem 4: "Port 8080 bereits belegt"

**Fehler**: Service startet nicht, Port 8080 wird schon verwendet

**Lösung 1** - Anderen Prozess beenden:
1. **Windows-Taste + R** drücken
2. Eingeben: `resmon` → Enter
3. Reiter "Netzwerk" öffnen
4. Nach "8080" suchen
5. Prozess beenden

**Lösung 2** - Anderen Port verwenden:
1. Öffnen Sie `media_http_server.py` mit Notepad
2. Suchen Sie die Zeile: `PORT = 8080`
3. Ändern Sie zu: `PORT = 8081` (oder eine andere Zahl)
4. Speichern Sie die Datei
5. Wiederholen Sie Schritt 4

---

### Problem 5: Browser zeigt nichts an

**Fehler**: `http://localhost:8080` zeigt: "Diese Seite kann nicht angezeigt werden"

**Prüfen Sie**:
1. Läuft der Service? → `check_service_status.bat` ausführen
2. Ist Port 8080 belegt? → Sollte in Status-Prüfung stehen
3. Python installiert? → In Eingabeaufforderung: `python --version`

**Lösung**:
1. Service neu starten:
   - **Windows-Taste + R**
   - Eingeben: `services.msc` → Enter
   - Suchen: "WeltenbibliothekMediaServer"
   - Rechtsklick → "Neu starten"
2. Dann Browser neu laden

---

### Problem 6: Firewall blockiert

**Fehler**: Von anderen Geräten im Netzwerk nicht erreichbar

**Lösung**:
1. **Windows-Taste + R** drücken
2. Eingeben: `cmd` → **Strg+Shift+Enter** (als Administrator)
3. Kopieren und einfügen:
   ```
   netsh advfirewall firewall add rule name="Weltenbibliothek HTTP" dir=in action=allow protocol=TCP localport=8080
   ```
4. Enter drücken
5. Sollte zeigen: "OK"

---

## 🔧 Nützliche Befehle

### Service verwalten

**Service stoppen**:
1. Windows-Taste + R
2. Eingeben: `cmd` → Enter
3. Eingeben: `net stop WeltenbibliothekMediaServer`

**Service starten**:
1. Windows-Taste + R
2. Eingeben: `cmd` → Enter
3. Eingeben: `net start WeltenbibliothekMediaServer`

**Service neu starten**:
1. Windows-Taste + R
2. Eingeben: `cmd` → Enter
3. Eingeben: `net stop WeltenbibliothekMediaServer & net start WeltenbibliothekMediaServer`

---

### Service komplett entfernen

**Wenn Sie den Service nicht mehr brauchen**:

1. Gehen Sie zu: `C:\Users\[IhrName]\flutter_app\scripts\`
2. **Rechtsklick** auf: `uninstall_http_service.bat`
3. "Als Administrator ausführen"
4. Fertig - Service ist entfernt

---

## 📊 Was bedeuten die Dateien?

| Datei | Was macht sie? | Wann brauche ich sie? |
|-------|----------------|----------------------|
| `media_http_server.py` | Das ist der Server (Python-Code) | Immer - wird automatisch ausgeführt |
| `start_media_server.bat` | Startet Server manuell (zum Testen) | Nur zum Testen ohne Service |
| `install_http_service.bat` | Installiert Windows-Dienst | **Einmal beim Setup** |
| `uninstall_http_service.bat` | Entfernt Windows-Dienst | Wenn Sie es nicht mehr brauchen |
| `check_service_status.bat` | Zeigt ob alles funktioniert | Immer wenn Sie prüfen wollen |
| `nssm.exe` | Hilfsprogramm für Windows-Dienste | Wird von install_http_service.bat benutzt |

---

## 💡 Tipps

### Manuell testen (ohne Service)

**Wenn Sie erst mal testen wollen** ohne den Service zu installieren:

1. **Doppelklick** auf: `start_media_server.bat`
2. Ein schwarzes Fenster öffnet sich
3. Server läuft jetzt - **Fenster offen lassen!**
4. Testen Sie: `http://localhost:8080` im Browser
5. Zum Beenden: Fenster schließen

**Nachteil**: Server stoppt wenn Sie Fenster schließen oder Windows neu starten

**Vorteil**: Schneller Test ohne Admin-Rechte

---

### Nach Windows-Neustart

**Was passiert nach einem Windows-Neustart?**

- ✅ Service startet **automatisch**
- ✅ Sie müssen **nichts** machen
- ✅ Server läuft im Hintergrund

**Zum Prüfen**:
1. Nach Windows-Start warten (ca. 30 Sekunden)
2. Browser öffnen: `http://localhost:8080`
3. Sollte sofort funktionieren

---

## 📱 Flutter App verbinden

**Nachdem der Server läuft**:

1. **Öffnen Sie** die Weltenbibliothek App auf Android
2. **Gehen Sie** zur Telegram-Seite
3. **Warten Sie** 2-3 Sekunden
4. **Bilder sollten** jetzt geladen werden!

**Wenn Bilder nicht laden**:
- Sind Handy und PC im gleichen WLAN?
- Läuft der Server? → `http://localhost:8080` im PC-Browser testen
- Läuft die Telegram-Synchronisation? → Müssen die PHP-Scripts laufen

---

## ✅ Checkliste

Haken Sie ab, was Sie erledigt haben:

- [ ] Schritt 1: Ordner erstellt (`C:\Users\[IhrName]\flutter_app\scripts\`)
- [ ] Schritt 2: 5 Dateien heruntergeladen
- [ ] Schritt 3: NSSM heruntergeladen und kopiert (nssm.exe)
- [ ] Schritt 4: Service installiert (install_http_service.bat als Admin)
- [ ] Schritt 5: Status geprüft (check_service_status.bat)
- [ ] Schritt 6: Browser-Test erfolgreich (`http://localhost:8080`)
- [ ] Windows neu gestartet und Service läuft automatisch
- [ ] Flutter App zeigt Bilder

---

## 🎯 Häufig gestellte Fragen

**F: Muss ich das nach jedem Windows-Neustart wiederholen?**
A: **Nein!** Der Service startet automatisch. Einmal installieren reicht.

**F: Sieht man ein Fenster wenn der Server läuft?**
A: **Nein.** Der Service läuft unsichtbar im Hintergrund.

**F: Kann ich den Server stoppen?**
A: **Ja.** Mit: `net stop WeltenbibliothekMediaServer` in der Eingabeaufforderung.

**F: Wie viel RAM/CPU braucht der Server?**
A: Sehr wenig - ca. 20 MB RAM, fast keine CPU.

**F: Funktioniert es auch ohne Internet?**
A: **Ja**, im lokalen Netzwerk. Für externes Zugriff brauchen Sie Internet.

**F: Was ist der Unterschied zu FTP?**
A: FTP ist für Upload (Telegram → PC), HTTP für Download (PC → Flutter App).

**F: Muss der FTP-Server laufen?**
A: Nicht direkt, aber die Dateien müssen auf der Festplatte sein (`C:\xlight\Weltenbibliothek\`).

**F: Kann ich den Port ändern?**
A: **Ja.** Öffnen Sie `media_http_server.py` und ändern Sie `PORT = 8080` zu einer anderen Zahl.

---

## 📞 Weitere Hilfe

**Wenn Sie nicht weiterkommen**:

1. **Prüfen Sie**: `check_service_status.bat` ausführen
2. **Lesen Sie**: Die Fehlermeldung genau durch
3. **Suchen Sie**: In dieser Anleitung unter "Hilfe bei Problemen"
4. **Log-Dateien**: Im Ordner `scripts\` nach Dateien mit `.log` suchen

**Log-Dateien**:
- `http_service.log` - Normale Ausgaben
- `http_service_error.log` - Fehler

---

**Erstellt für**: Weltenbibliothek Projekt  
**Version**: 1.0 (Einfache Anleitung)  
**Datum**: November 2025

---

**Viel Erfolg! 🚀**
