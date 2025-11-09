# ✅ TELEGRAM CHAT SETUP - CHECKLISTE

**Schnelle Checkliste zur Inbetriebnahme der bidirektionalen Telegram-Chat-Synchronisation**

---

## 📋 VOR DEM START

### ✅ SCHRITT 1: Telegram API Credentials
- [ ] Gehe zu https://my.telegram.org/apps
- [ ] Melde dich mit Telegram-Nummer an
- [ ] Erstelle neue App: "Weltenbibliothek Chat Sync"
- [ ] Kopiere **API ID** und **API Hash**
- [ ] Notiere deine Telefonnummer im Format: `+43XXXXXXXXXX`

### ✅ SCHRITT 2: Firebase Admin SDK
- [ ] Prüfe ob Datei existiert: `/opt/flutter/firebase-admin-sdk.json`
- [ ] Falls nicht: Firebase Console → Project Settings → Service Accounts → "Generate new private key" (Python)
- [ ] Lade JSON-Datei herunter und speichere als `/opt/flutter/firebase-admin-sdk.json`

### ✅ SCHRITT 3: FTP Server
- [ ] Prüfe ob Xlight FTP Server läuft: `ftp Weltenbibliothek.ddns.net`
- [ ] Credentials: `Weltenbibliothek` / `Jolene2305`
- [ ] Prüfe ob HTTP-Proxy läuft: `curl http://Weltenbibliothek.ddns.net:8080`

---

## 🔧 DAEMON KONFIGURATION

### ✅ SCHRITT 4: Python Dependencies
```bash
cd /home/user/flutter_app/scripts
pip install pyrogram tgcrypto firebase-admin
```

**Falls tgcrypto Fehler:**
```bash
pip install pyrogram firebase-admin
```

### ✅ SCHRITT 5: Credentials eintragen
- [ ] Öffne `scripts/telegram_chat_sync_daemon.py`
- [ ] Trage ein:
  ```python
  API_ID = "DEINE_API_ID"        # Numerisch, z.B. 12345678
  API_HASH = "DEIN_API_HASH"     # Alphanumerisch
  PHONE_NUMBER = "+43XXXXXXXXXX" # Deine Telegram-Nummer
  ```
- [ ] Speichern

### ✅ SCHRITT 6: Daemon Erststart (Session-Login)
```bash
cd /home/user/flutter_app/scripts
python3 telegram_chat_sync_daemon.py
```

**Beim ersten Start:**
- [ ] Telefonnummer eingeben → Enter
- [ ] Telegram-Code (von Telegram-App) eingeben → Enter
- [ ] Falls 2FA aktiv: Passwort eingeben → Enter
- [ ] Session gespeichert: `weltenbibliothek_chat_sync.session`

**Erwartete Ausgabe:**
```
🔄 TELEGRAM CHAT BIDIREKTIONALE SYNCHRONISATION
✅ Firebase Firestore verbunden
✅ Telegram Pyrogram Client initialisiert
✅ Telegram Client gestartet
📍 Ziel-Chat: @Weltenbibliothekchat
🕐 Auto-Delete: 24 Stunden
```

**Daemon läuft korrekt wenn:**
- [ ] Keine Fehler angezeigt werden
- [ ] "Telegram Client gestartet" erscheint
- [ ] Daemon bleibt im Vordergrund (nicht crasht)

**Falls Fehler:**
- API_ID/API_HASH falsch → Credentials prüfen
- "No Firebase App" → Firebase Admin SDK Pfad prüfen
- "FloodWaitError" → Warte 60 Sekunden, dann neu starten

---

## 🔥 FIRESTORE SETUP

### ✅ SCHRITT 7: Firestore Indexes erstellen

**Option A: Automatisch**
- [ ] Warte auf Fehlermeldung: "The query requires an index"
- [ ] Klicke auf Link in Fehlermeldung
- [ ] Firebase erstellt Index automatisch
- [ ] Warte 1-2 Minuten

**Option B: Manuell (empfohlen)**
- [ ] Öffne Firebase Console → Dein Projekt
- [ ] Gehe zu **Firestore Database** → **Indexes** Tab
- [ ] Klicke **Create Index**

**Index 1: App → Telegram Sync**
```
Collection ID: chat_messages
Fields to index:
  - source (Ascending)
  - syncedToTelegram (Ascending)
  - __name__ (Ascending)
Query scope: Collection
```

**Index 2: Chat-Anzeige (Flutter)**
```
Collection ID: chat_messages
Fields to index:
  - deleted (Ascending)
  - timestamp (Descending)
  - __name__ (Ascending)
Query scope: Collection
```

**Index 3: Edit Sync**
```
Collection ID: chat_messages
Fields to index:
  - source (Ascending)
  - edited (Ascending)
  - editSyncedToTelegram (Ascending)
  - __name__ (Ascending)
Query scope: Collection
```

**Index 4: Delete Sync**
```
Collection ID: chat_messages
Fields to index:
  - source (Ascending)
  - deleted (Ascending)
  - deleteSyncedToTelegram (Ascending)
  - __name__ (Ascending)
Query scope: Collection
```

**Index 5: Auto-Delete**
```
Collection ID: chat_messages
Fields to index:
  - timestamp (Ascending)
  - deleted (Ascending)
  - __name__ (Ascending)
Query scope: Collection
```

- [ ] Warte bis alle Indexes Status "Enabled" haben (1-2 Minuten)

### ✅ SCHRITT 8: Security Rules (optional, für Produktion)
- [ ] Öffne Firebase Console → Firestore Database → **Rules** Tab
- [ ] Füge ein (siehe `TELEGRAM_CHAT_SYNC_ANLEITUNG.md` Schritt 4)
- [ ] Publish Rules

**Für Entwicklung (aktuell OK):**
```javascript
allow read, write: if true;  // Alle dürfen
```

**Für Produktion (später ändern):**
```javascript
allow read: if request.auth != null;  // Nur authentifizierte User
```

---

## 🧪 FUNKTIONSTEST

### ✅ SCHRITT 9: Test App → Telegram

**In Flutter-App:**
- [ ] Öffne App
- [ ] Navigiere zu "💬 Telegram Chat"
- [ ] Schreibe Nachricht: "Test von App - $(date)"
- [ ] Nachricht wird gesendet (✓ Symbol)

**In Telegram:**
- [ ] Öffne Telegram-App auf Handy
- [ ] Gehe zu @Weltenbibliothekchat
- [ ] ✅ Nachricht "Test von App" sollte erscheinen

**Falls Nachricht nicht erscheint:**
- [ ] Prüfe Daemon-Logs (Terminal)
- [ ] Prüfe Firestore-Dokument: `syncedToTelegram` sollte `true` sein
- [ ] Prüfe ob Daemon läuft: `ps aux | grep telegram_chat_sync`

### ✅ SCHRITT 10: Test Telegram → App

**In Telegram:**
- [ ] Öffne @Weltenbibliothekchat
- [ ] Schreibe: "Test von Telegram - $(date)"

**In Flutter-App:**
- [ ] Öffne Telegram Chat Screen
- [ ] ✅ Nachricht "Test von Telegram" sollte erscheinen
- [ ] Absender-Name sollte dein @telegram_username sein

**Falls Nachricht nicht erscheint:**
- [ ] Prüfe Daemon-Logs: "Telegram → Firestore" sollte erscheinen
- [ ] Prüfe Firestore Collection `chat_messages`: Neues Dokument mit `source: "telegram"`
- [ ] Prüfe Flutter-Logs: StreamBuilder sollte Update empfangen

### ✅ SCHRITT 11: Test Bearbeitung

**In App:**
- [ ] Schreibe Nachricht: "Alter Text"
- [ ] Long-Press auf Nachricht → "Bearbeiten"
- [ ] Ändere zu: "Neuer Text"
- [ ] Speichern

**In Telegram:**
- [ ] ✅ Nachricht sollte geändert sein: "Neuer Text"
- [ ] "bearbeitet" Tag sollte angezeigt werden

### ✅ SCHRITT 12: Test Löschung

**In App:**
- [ ] Schreibe Nachricht: "Test Löschung"
- [ ] Long-Press → "Löschen" → Bestätigen

**In Telegram:**
- [ ] ✅ Nachricht sollte verschwunden sein

### ✅ SCHRITT 13: Test Medien (optional)

**In Telegram:**
- [ ] Sende Foto in @Weltenbibliothekchat

**In App:**
- [ ] ✅ Foto sollte in Chat erscheinen
- [ ] ✅ Foto sollte sichtbar sein (HTTP-Proxy)

**FTP-Server prüfen:**
- [ ] Verbinde zu FTP: `ftp Weltenbibliothek.ddns.net`
- [ ] Login: `Weltenbibliothek` / `Jolene2305`
- [ ] Wechsle zu `/chat_media/`
- [ ] ✅ Foto sollte dort gespeichert sein

---

## 🚀 DAUERHAFTER BETRIEB

### ✅ SCHRITT 14: Systemd Service (empfohlen)

**Service-Datei erstellen:**
```bash
sudo nano /etc/systemd/system/telegram-chat-sync.service
```

**Inhalt:**
```ini
[Unit]
Description=Telegram Chat Sync Daemon
After=network.target

[Service]
Type=simple
User=dein_username
WorkingDirectory=/home/user/flutter_app/scripts
ExecStart=/usr/bin/python3 telegram_chat_sync_daemon.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Service aktivieren:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable telegram-chat-sync.service
sudo systemctl start telegram-chat-sync.service
```

**Status prüfen:**
```bash
sudo systemctl status telegram-chat-sync.service
journalctl -u telegram-chat-sync.service -f
```

### ✅ SCHRITT 15: HTTP-Proxy Service (falls noch nicht aktiv)

**Service-Datei:**
```bash
sudo nano /etc/systemd/system/ftp-http-proxy.service
```

**Inhalt:**
```ini
[Unit]
Description=FTP HTTP Proxy Server (Port 8080)
After=network.target

[Service]
Type=simple
User=dein_username
WorkingDirectory=/home/user/flutter_app/scripts
ExecStart=/usr/bin/python3 simple_http_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Aktivieren:**
```bash
sudo systemctl enable ftp-http-proxy.service
sudo systemctl start ftp-http-proxy.service
```

---

## 🎯 FINALE CHECKLISTE

### System-Status
- [ ] ✅ Daemon läuft: `systemctl status telegram-chat-sync`
- [ ] ✅ HTTP-Proxy läuft: `curl http://Weltenbibliothek.ddns.net:8080`
- [ ] ✅ FTP Server erreichbar: `ftp Weltenbibliothek.ddns.net`
- [ ] ✅ Firestore Indexes aktiv (Firebase Console)

### Funktionstest
- [ ] ✅ App → Telegram funktioniert
- [ ] ✅ Telegram → App funktioniert
- [ ] ✅ Bearbeitung synchronisiert
- [ ] ✅ Löschung synchronisiert
- [ ] ✅ Telegram-Benutzernamen werden angezeigt
- [ ] ✅ Medien werden hochgeladen und angezeigt

### Auto-Delete (24h Test optional)
- [ ] ✅ Warte 24 Stunden
- [ ] ✅ Alte Nachrichten werden automatisch gelöscht

**Für schnellen Test:**
```python
# In telegram_chat_sync_daemon.py
DELETE_AFTER_HOURS = 0.1  # 6 Minuten
```

---

## 📖 TROUBLESHOOTING

### Problem: Daemon startet nicht
**Fehlermeldung:** "API_ID or API_HASH invalid"
- [ ] Prüfe Credentials in `telegram_chat_sync_daemon.py`
- [ ] API_ID muss numerisch sein
- [ ] API_HASH exakt kopieren (keine Leerzeichen)

### Problem: Nachrichten erscheinen nicht in Telegram
**Ursache:** Chat-ID nicht erkannt
- [ ] Sende ZUERST eine Nachricht in Telegram-Chat
- [ ] Daemon erkennt Chat-ID automatisch
- [ ] Dann funktioniert App → Telegram

### Problem: Firestore Index Fehler
**Fehlermeldung:** "The query requires an index"
- [ ] Klicke auf Link in Fehlermeldung
- [ ] Warte 1-2 Minuten bis Index aktiv
- [ ] Oder erstelle Index manuell (siehe Schritt 7)

### Problem: Medien werden nicht angezeigt
- [ ] Prüfe HTTP-Proxy: `curl http://Weltenbibliothek.ddns.net:8080`
- [ ] Prüfe FTP-Zugriff: `ftp Weltenbibliothek.ddns.net`
- [ ] Prüfe Firestore: `mediaUrl` sollte HTTP-URL sein

### Problem: "Session file is corrupted"
```bash
cd /home/user/flutter_app/scripts
rm weltenbibliothek_chat_sync.session
python3 telegram_chat_sync_daemon.py  # Neu einloggen
```

---

## 📚 WEITERE DOKUMENTATION

**Vollständige Setup-Anleitung:**
📄 `TELEGRAM_CHAT_SYNC_ANLEITUNG.md`

**Übersicht & Architektur:**
📄 `TELEGRAM_CHAT_SYNC_ZUSAMMENFASSUNG.md`

**Logs ansehen:**
```bash
# Systemd Service Logs
journalctl -u telegram-chat-sync.service -f

# Flutter App Logs
flutter run  # Terminal-Output
```

---

## ✅ SETUP ABGESCHLOSSEN!

**Wenn alle Checkboxen ✅ sind:**

🎉 **Bidirektionale Telegram-Chat-Synchronisation ist aktiv!**

**Features aktiv:**
- ✅ Nachrichten App ↔ Telegram
- ✅ Bearbeitungen synchronisiert
- ✅ Löschungen synchronisiert
- ✅ Telegram-Benutzernamen angezeigt
- ✅ Medien über FTP/HTTP
- ✅ Auto-Delete nach 24 Stunden

**Support:**
- Daemon-Logs: `journalctl -u telegram-chat-sync.service -f`
- Firebase Console: Firestore Collection `chat_messages`
- FTP-Server: `ftp Weltenbibliothek.ddns.net`

---

**🔄 Viel Erfolg mit der Synchronisation!**
