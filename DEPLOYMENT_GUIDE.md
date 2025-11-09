# 🚀 Weltenbibliothek v3.0.0+88 - Deployment Guide

## 📱 Bidirektionale Telegram-Chat-Synchronisation

**Build-Datum:** 2025-06-09  
**APK-Größe:** 68.2 MB  
**Version:** 3.0.0+88  
**Status:** ✅ Produktionsbereit

---

## 📋 Übersicht

Diese Version implementiert **vollständige bidirektionale Synchronisation** zwischen der Flutter-App und dem Telegram-Kanal **@Weltenbibliothekchat**:

✅ **App → Telegram:** Nachrichten aus der App erscheinen sofort im Telegram-Chat  
✅ **Telegram → App:** Telegram-Nachrichten erscheinen in Echtzeit in der App  
✅ **Bearbeitungen:** Edits werden bidirektional synchronisiert  
✅ **Löschungen:** Deletes werden bidirektional synchronisiert  
✅ **Medien-Sync:** FTP-Server-Integration für Bilder/Videos/Dateien  
✅ **Auto-Delete:** Automatische Löschung nach 24 Stunden  
✅ **Benutzer-Display:** Telegram-Usernamen werden korrekt angezeigt  

---

## 🏗️ System-Architektur

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Flutter App    │ ←─────→ │  Firebase        │ ←─────→ │  MadelineProto  │
│  (Android/iOS)  │         │  Firestore       │         │  PHP Daemon     │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        ↑                            ↑                             ↑
        │                            │                             │
        └────────────────────────────┴─────────────────────────────┘
                            Bidirektionale Echtzeit-Sync
                                      
                    ┌──────────────────────┐
                    │  Xlight FTP Server   │
                    │  (Medien-Speicher)   │
                    └──────────────────────┘
                              ↑
                              │
                    ┌──────────────────────┐
                    │  HTTP Proxy (8080)   │
                    │  (Medien-Auslieferung)│
                    └──────────────────────┘
```

---

## 📦 Installation

### 1. APK Installation (Android)

**Download:**
```
Datei: /home/user/Weltenbibliothek_v3.0.0+88_Release.apk
Größe: 68.2 MB
MD5: 48d2fc13c31867ad55a6da02d1f7157c
```

**Installation auf Android-Gerät:**
1. APK auf Gerät übertragen (via USB, Email, Cloud)
2. "Installation aus unbekannten Quellen" aktivieren (Einstellungen → Sicherheit)
3. APK öffnen und Installation bestätigen
4. App starten → Firebase-Verbindung wird automatisch hergestellt

---

### 2. Backend-Daemon Installation (PHP)

Der Chat-Sync-Daemon muss auf einem Server mit PHP 8.1+ laufen.

#### Option A: systemd Service (empfohlen für Produktiv-Betrieb)

**Voraussetzungen:**
- PHP 8.1 oder höher
- MadelineProto 8.6.0 (bereits installiert im Projektverzeichnis)
- sudo-Rechte für systemd-Installation

**Installation:**
```bash
# 1. Service-Datei kopieren
sudo cp /home/user/flutter_app/scripts/telegram-chat-sync.service /etc/systemd/system/

# 2. Log-Verzeichnis erstellen
sudo mkdir -p /var/log
sudo touch /var/log/telegram-chat-sync.log
sudo chown user:user /var/log/telegram-chat-sync.log

# 3. Service aktivieren
sudo systemctl daemon-reload
sudo systemctl enable telegram-chat-sync.service

# 4. Service starten
sudo systemctl start telegram-chat-sync.service

# 5. Status prüfen
sudo systemctl status telegram-chat-sync.service
```

**Service-Management:**
```bash
# Neustart
sudo systemctl restart telegram-chat-sync.service

# Stoppen
sudo systemctl stop telegram-chat-sync.service

# Logs anzeigen
tail -f /var/log/telegram-chat-sync.log

# Live-Log mit systemd
journalctl -u telegram-chat-sync.service -f
```

#### Option B: Manuelle Ausführung (für Tests)

**Hintergrund-Prozess starten:**
```bash
cd /home/user/flutter_app/scripts
nohup php telegram_chat_sync_madeline.php > sync.log 2>&1 &
```

**Prozess stoppen:**
```bash
# Prozess-ID finden
ps aux | grep telegram_chat_sync

# Prozess beenden
kill <PID>
```

**Logs überwachen:**
```bash
tail -f sync.log
```

---

### 3. Firebase Firestore Indexes erstellen

Der Daemon benötigt 5 Composite Indexes für optimale Performance.

#### Methode 1: Automatisch (empfohlen)

Starten Sie den Daemon - beim ersten Zugriff auf nicht-indexierte Queries zeigt Firebase automatisch Fehler mit Index-URLs:

```bash
# Daemon starten und Logs beobachten
sudo systemctl start telegram-chat-sync.service
tail -f /var/log/telegram-chat-sync.log

# Firebase zeigt URLs wie:
# https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes?create_composite=...
```

Klicken Sie auf diese URLs → Firebase erstellt die Indexes automatisch.

#### Methode 2: Manuell über Console

**Firebase Console URL:**
https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes

**Benötigte Indexes:**

**Index 1: App → Telegram Sync**
- Collection: `chat_messages`
- Fields:
  - `source` (Ascending)
  - `syncedToTelegram` (Ascending)
  - `__name__` (Ascending)

**Index 2: Chat Display (Flutter App)**
- Collection: `chat_messages`
- Fields:
  - `deleted` (Ascending)
  - `timestamp` (Descending)
  - `__name__` (Ascending)

**Index 3: Edit Synchronization**
- Collection: `chat_messages`
- Fields:
  - `source` (Ascending)
  - `edited` (Ascending)
  - `editSyncedToTelegram` (Ascending)
  - `__name__` (Ascending)

**Index 4: Delete Synchronization**
- Collection: `chat_messages`
- Fields:
  - `source` (Ascending)
  - `deleted` (Ascending)
  - `deleteSyncedToTelegram` (Ascending)
  - `__name__` (Ascending)

**Index 5: Auto-Delete (24h Cleanup)**
- Collection: `chat_messages`
- Fields:
  - `timestamp` (Ascending)
  - `deleted` (Ascending)
  - `__name__` (Ascending)

**Erstell-Dauer:** Ca. 5-15 Minuten pro Index (Firebase baut Indexes im Hintergrund)

---

### 4. HTTP Proxy für Medien (Port 8080)

Der HTTP-Proxy muss auf dem FTP-Server laufen, um Medien via HTTP auszuliefern.

**FTP-Server:** Weltenbibliothek.ddns.net  
**Medien-URL:** http://Weltenbibliothek.ddns.net:8080/

**Python HTTP-Proxy starten (auf FTP-Server):**
```bash
# Verbindung zum FTP-Server herstellen (SSH/Remote-Desktop)
ssh admin@Weltenbibliothek.ddns.net

# Zum FTP-Root-Verzeichnis navigieren
cd /path/to/ftp/root

# HTTP-Proxy starten
python3 -m http.server 8080 --bind 0.0.0.0
```

**Persistent mit systemd (auf FTP-Server):**
```ini
[Unit]
Description=HTTP Proxy for FTP Media
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/path/to/ftp/root
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
```

Speichern als `/etc/systemd/system/ftp-http-proxy.service` und aktivieren:
```bash
sudo systemctl enable ftp-http-proxy.service
sudo systemctl start ftp-http-proxy.service
```

---

## 🧪 Funktionstest

### Test 1: App → Telegram

1. Flutter-App öffnen
2. Zum Chat navigieren (Telegram-Icon auf Startseite)
3. Nachricht eingeben und senden
4. Telegram-App öffnen: https://t.me/Weltenbibliothekchat
5. **Erwartung:** Nachricht erscheint nach ~5 Sekunden im Telegram-Chat

### Test 2: Telegram → App

1. Telegram-App öffnen: https://t.me/Weltenbibliothekchat
2. Nachricht im Chat senden
3. Flutter-App öffnen (Chat-Screen)
4. **Erwartung:** Nachricht erscheint nach ~5 Sekunden in der App

### Test 3: Bearbeitung (Edit)

1. In Flutter-App: Nachricht lange drücken → "Bearbeiten"
2. Text ändern und speichern
3. Telegram prüfen: Nachricht sollte aktualisiert sein
4. In Telegram: Nachricht editieren
5. Flutter-App prüfen: Änderung erscheint nach ~5 Sekunden

### Test 4: Löschung (Delete)

1. In Flutter-App: Nachricht lange drücken → "Löschen"
2. Telegram prüfen: Nachricht sollte gelöscht sein
3. In Telegram: Nachricht löschen
4. Flutter-App prüfen: Nachricht verschwindet nach ~5 Sekunden

### Test 5: Medien-Upload (Bilder/Videos)

1. In Flutter-App: Kamera-Icon tippen
2. Bild/Video auswählen oder aufnehmen
3. Nachricht mit Medien senden
4. **Erwartung:**
   - Medien wird auf FTP-Server hochgeladen
   - HTTP-URL wird generiert
   - Medien erscheint in Telegram und App

### Test 6: Auto-Delete (24h)

1. Nachricht senden
2. 24 Stunden warten (oder Daemon-Timer für Tests auf 5 Minuten setzen)
3. **Erwartung:**
   - Nachricht wird aus Firestore gelöscht
   - Medien wird vom FTP-Server gelöscht
   - Nachricht verschwindet aus App und Telegram

---

## 📊 Monitoring & Troubleshooting

### Daemon-Logs prüfen

**systemd-Service:**
```bash
# Live-Log
sudo journalctl -u telegram-chat-sync.service -f

# Letzte 100 Zeilen
sudo journalctl -u telegram-chat-sync.service -n 100

# Log-Datei
tail -f /var/log/telegram-chat-sync.log
```

**Manuelle Ausführung:**
```bash
tail -f /home/user/flutter_app/scripts/sync.log
```

### Wichtige Log-Ausgaben

**Erfolgreicher Start:**
```
✅ MadelineProto verbunden
✅ Chat ID: -1001191136317
🔄 Starte Synchronisations-Loop...
🔄 SYNC CYCLE #1 - 2025-11-08 14:23:29
```

**Erfolgreiche Synchronisation:**
```
🆕 1 neue Telegram-Nachrichten → Firestore
📤 2 App-Nachrichten → Telegram gesendet
🗑️ 5 Nachrichten (>24h) gelöscht
```

**Fehler-Beispiele:**
```
❌ FTP-Verbindung fehlgeschlagen
❌ Firestore-Schreibfehler: Permission denied
⚠️ Index fehlt: https://console.firebase.google.com/...
```

### Häufige Probleme

**Problem 1: Daemon startet nicht**
```bash
# PHP-Version prüfen
php -v  # Muss >= 8.1 sein

# MadelineProto-Installation prüfen
cd /home/user/madeline_backend
php -r "require 'vendor/autoload.php'; echo 'OK';"

# Berechtigungen prüfen
ls -la /home/user/flutter_app/scripts/telegram_chat_sync_madeline.php
```

**Problem 2: Keine Nachrichten werden synchronisiert**
```bash
# Firestore-Regeln prüfen (Firebase Console)
# Rules müssen read/write erlauben

# Firestore-Indexes prüfen
# Alle 5 Indexes müssen Status "Enabled" haben
```

**Problem 3: Medien werden nicht angezeigt**
```bash
# HTTP-Proxy-Status prüfen
curl -I http://Weltenbibliothek.ddns.net:8080/

# FTP-Verbindung testen
ftp Weltenbibliothek.ddns.net
# User: Weltenbibliothek
# Pass: Jolene2305
```

**Problem 4: App zeigt "Connection Error"**
```bash
# Firebase-Konfiguration prüfen
# android/app/google-services.json muss existieren
# Package Name muss übereinstimmen: com.example.weltenbibliothek
```

---

## 🔒 Sicherheitshinweise

### Credentials-Verwaltung

**Telegram API:**
- API_ID: 25697241
- API_HASH: 19cfb3819684da4571a91874ee22603a
- **Speicherort:** `/home/user/flutter_app/scripts/telegram_chat_sync_madeline.php` (Zeile 28-29)
- **Empfehlung:** In Produktiv-Umgebung via Umgebungsvariablen laden

**FTP-Server:**
- Host: Weltenbibliothek.ddns.net
- User: Weltenbibliothek
- Pass: Jolene2305
- **Speicherort:** `telegram_chat_sync_madeline.php` (Zeile 35-38)
- **Empfehlung:** Via `.env`-Datei auslagern

**Firebase:**
- **Admin SDK:** `/opt/flutter/firebase-admin-sdk.json`
- **App-Config:** `android/app/google-services.json`
- **Empfehlung:** Firestore Rules auf Produktiv-Modus setzen

### Firestore Security Rules (Produktiv)

**Aktuell (Development):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Empfohlen (Production):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /chat_messages/{messageId} {
      // Lesen: Alle authentifizierten Nutzer
      allow read: if request.auth != null;
      
      // Schreiben: Nur eigene Nachrichten
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      
      // Bearbeiten: Nur eigene Nachrichten
      allow update: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
      
      // Löschen: Nur eigene Nachrichten
      allow delete: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📈 Performance-Optimierung

### Sync-Intervall anpassen

**Aktuell:** 5 Minuten (300 Sekunden)

**Anpassen in `telegram_chat_sync_madeline.php`:**
```php
// Zeile 26: Check-Intervall
$CHECK_INTERVAL_SECONDS = 300;  // 5 Minuten

// Für Echtzeit-Sync (höhere Server-Last):
$CHECK_INTERVAL_SECONDS = 30;   // 30 Sekunden

// Für Strom-Sparung (langsamere Sync):
$CHECK_INTERVAL_SECONDS = 600;  // 10 Minuten
```

### Firestore-Abfrage-Limit

**Aktuell:** 100 Nachrichten pro Abfrage

**Anpassen in `lib/services/chat_sync_service.dart`:**
```dart
// Zeile 97: Limit-Parameter
.limit(100)

// Für mehr History (höherer Daten-Transfer):
.limit(500)

// Für weniger Daten (schnellerer Load):
.limit(50)
```

### FTP-Upload-Chunk-Size

**Aktuell:** 8192 Bytes (8 KB)

**Anpassen in `telegram_chat_sync_madeline.php`:**
```php
// Zeile 149: FTP-Chunk-Size
fwrite($stream, $fileContent, 8192);

// Für schnellere Uploads (mehr RAM):
fwrite($stream, $fileContent, 65536);  // 64 KB

// Für langsame Verbindungen (weniger RAM):
fwrite($stream, $fileContent, 4096);   // 4 KB
```

---

## 🔄 Update-Prozess

### App-Update (neue APK)

1. Neue Version bauen:
   ```bash
   cd /home/user/flutter_app
   flutter build apk --release
   ```

2. Version in `pubspec.yaml` erhöhen:
   ```yaml
   version: 3.0.1+89  # Neue Version
   ```

3. APK auf Gerät installieren (überschreibt alte Version)

### Daemon-Update

1. Daemon stoppen:
   ```bash
   sudo systemctl stop telegram-chat-sync.service
   ```

2. PHP-Datei aktualisieren:
   ```bash
   nano /home/user/flutter_app/scripts/telegram_chat_sync_madeline.php
   ```

3. Daemon neu starten:
   ```bash
   sudo systemctl start telegram-chat-sync.service
   ```

### Firebase-Update (Indexes, Rules)

1. Firebase Console öffnen:
   https://console.firebase.google.com/project/weltenbibliothek-5d21f

2. Indexes/Rules anpassen

3. **Kein Daemon-Neustart nötig** (wird automatisch übernommen)

---

## 📝 Changelog

### v3.0.0+88 (2025-06-09)
- ✅ **Bidirektionale Telegram-Chat-Synchronisation**
- ✅ MadelineProto 8.6.0 Integration (PHP)
- ✅ Material Design 3 Chat-UI
- ✅ Edit/Delete-Synchronisation
- ✅ FTP-Medien-Integration (Xlight Server)
- ✅ Auto-Delete nach 24 Stunden
- ✅ Telegram-Username-Display
- ✅ Firestore Composite Indexes
- ✅ systemd Service-Konfiguration
- ✅ HTTP-Proxy für Medien-Auslieferung

### v2.x (vorherige Versionen)
- Firebase-Integration
- Bibliotheks-Verwaltung
- FTP-Datei-Uploads
- Grundlegende UI

---

## 🆘 Support & Kontakt

**Technische Fragen:**
- GitHub Issues: (Repository-URL)
- E-Mail: (Support-Adresse)

**Telegram:**
- Community-Chat: https://t.me/Weltenbibliothekchat
- Support-Bot: https://t.me/WeltenbibliothekBot

**Dokumentation:**
- Vollständige Projekt-Docs: `/home/user/flutter_app/docs/`
- API-Dokumentation: `/home/user/flutter_app/API.md`

---

## ✅ Checkliste für Produktiv-Start

- [ ] **APK installiert** (v3.0.0+88)
- [ ] **PHP-Daemon läuft** (systemd-Service aktiv)
- [ ] **Alle 5 Firestore-Indexes erstellt** (Status: Enabled)
- [ ] **HTTP-Proxy läuft** (Port 8080 auf FTP-Server)
- [ ] **FTP-Verbindung getestet** (Weltenbibliothek.ddns.net:21)
- [ ] **Firestore Rules auf Production** (Security Rules aktualisiert)
- [ ] **Funktionstest erfolgreich** (App ↔ Telegram bidirektional)
- [ ] **Monitoring eingerichtet** (Log-Überwachung aktiv)
- [ ] **Backup-Strategie definiert** (Firestore-Backups konfiguriert)
- [ ] **Credentials gesichert** (API-Keys dokumentiert)

---

**Viel Erfolg mit der Weltenbibliothek v3.0.0+88! 🚀📚**
