# 🔄 TELEGRAM CHAT SYNCHRONISATION - SETUP ANLEITUNG

Komplette Anleitung zur Einrichtung der bidirektionalen Telegram-Chat-Synchronisation zwischen Flutter-App und Telegram-Chat.

---

## 📋 ÜBERSICHT

Diese Integration ermöglicht:

✅ **Bidirektionale Nachrichtensynchronisation**
- Nachrichten aus App → Telegram-Chat (@Weltenbibliothekchat)
- Nachrichten aus Telegram → App

✅ **Bearbeitungen synchronisieren**
- Bearbeitet ein Nutzer eine Nachricht in der App → erscheint in Telegram
- Bearbeitet ein Nutzer eine Nachricht in Telegram → erscheint in der App

✅ **Löschungen synchronisieren**
- Löscht ein Nutzer eine Nachricht in der App → wird aus Telegram gelöscht
- Löscht ein Nutzer eine Nachricht in Telegram → wird aus der App entfernt

✅ **Telegram-Benutzernamen anzeigen**
- Alle Telegram-Nutzer werden mit ihrem @username angezeigt
- App-Nutzer werden mit ihrem App-Username angezeigt

✅ **Medien-Support**
- Bilder, Videos, Audio-Dateien werden auf FTP-Server hochgeladen
- Medien-URLs werden in Firestore gespeichert
- Medien werden in App und Telegram angezeigt

✅ **Automatische Löschung**
- Nachrichten werden nach 24 Stunden automatisch gelöscht
- Löschung erfolgt aus: Telegram, FTP-Server, Firestore

---

## 🏗️ ARCHITEKTUR

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────┐
│   Flutter App   │ ←────→│    Firestore     │ ←────→│  Telegram Chat  │
│  (chat_sync_    │       │  (chat_messages) │       │ (@Weltenbib...  │
│   service.dart) │       │                  │       │      chat)      │
└─────────────────┘       └──────────────────┘       └─────────────────┘
                                    ↕                          ↕
                          ┌──────────────────┐       ┌─────────────────┐
                          │   FTP Server     │ ←────→│  Python Daemon  │
                          │  (Xlight)        │       │ (telegram_chat_ │
                          │  Medien-Storage  │       │  sync_daemon.py)│
                          └──────────────────┘       └─────────────────┘
                                    ↕
                          ┌──────────────────┐
                          │  HTTP Proxy      │
                          │  (Port 8080)     │
                          │  Medien-Zugriff  │
                          └──────────────────┘
```

**Datenfluss:**

1. **App → Telegram:**
   - Flutter schreibt Nachricht in Firestore (`source: "app"`, `syncedToTelegram: false`)
   - Python-Daemon erkennt neue Nachricht
   - Daemon sendet Nachricht zu Telegram
   - Daemon markiert in Firestore (`syncedToTelegram: true`)

2. **Telegram → App:**
   - Python-Daemon empfängt Telegram-Nachricht (Pyrogram Event)
   - Daemon speichert Nachricht in Firestore (`source: "telegram"`)
   - Flutter empfängt Update via Firestore-Listener
   - App zeigt Nachricht an

3. **Medien-Upload:**
   - Daemon lädt Medien von Telegram herunter
   - Daemon lädt Medien auf FTP-Server hoch
   - Daemon speichert HTTP-URL in Firestore
   - Flutter zeigt Medien via HTTP-Proxy an

4. **Auto-Delete:**
   - Daemon prüft alle 5 Minuten Timestamps
   - Nachrichten älter als 24h werden gelöscht
   - Löschung: Telegram → FTP → Firestore

---

## 🔧 SCHRITT 1: TELEGRAM API CREDENTIALS BESORGEN

**1.1 Telegram App erstellen:**

1. Besuche: https://my.telegram.org/apps
2. Melde dich mit deiner Telegram-Telefonnummer an
3. Klicke auf "Create new application"
4. Fülle das Formular aus:
   - **App title:** Weltenbibliothek Chat Sync
   - **Short name:** weltenbib_sync
   - **Platform:** Other
5. Speichere die Credentials:
   - **API ID** (numerisch, z.B. 12345678)
   - **API Hash** (alphanumerisch, z.B. 1234567890abcdef1234567890abcdef)

**1.2 Telefonnummer vorbereiten:**

- Deine Telegram-Telefonnummer im internationalen Format
- Beispiel: `+43XXXXXXXXXX` (Österreich)

---

## 🔧 SCHRITT 2: PYTHON-DAEMON KONFIGURIEREN

**2.1 Credentials eintragen:**

Öffne die Datei `scripts/telegram_chat_sync_daemon.py` und trage deine Credentials ein:

```python
# Telegram API Credentials (BITTE ANPASSEN!)
API_ID = "12345678"  # Deine API ID
API_HASH = "1234567890abcdef1234567890abcdef"  # Dein API Hash
PHONE_NUMBER = "+43XXXXXXXXXX"  # Deine Telefonnummer
CHAT_USERNAME = "@Weltenbibliothekchat"  # Ziel-Chat
```

**2.2 Dependencies installieren:**

```bash
cd /home/user/flutter_app/scripts
pip install pyrogram tgcrypto firebase-admin
```

**Wichtig:** Falls `tgcrypto` Probleme macht (C-Extension):

```bash
# Alternative: Ohne tgcrypto (langsamer, aber funktioniert immer)
pip install pyrogram firebase-admin
```

---

## 🔧 SCHRITT 3: FIRESTORE INDEXES ERSTELLEN

**3.1 Automatische Index-Erstellung:**

Beim ersten Start des Daemons werden automatisch Index-Anforderungen generiert. Firebase gibt Ihnen einen Link zur Index-Erstellung.

**3.2 Manuelle Index-Erstellung:**

Gehe zur Firebase Console:

1. **Projekt auswählen:** Dein Flutter-Projekt
2. **Firestore Database** → **Indexes** Tab
3. **Composite Index erstellen:**

**Index 1: App → Telegram Sync**
```
Collection: chat_messages
Fields:
  - source (Ascending)
  - syncedToTelegram (Ascending)
  - __name__ (Ascending)
```

**Index 2: Edit Sync**
```
Collection: chat_messages
Fields:
  - source (Ascending)
  - edited (Ascending)
  - editSyncedToTelegram (Ascending)
  - __name__ (Ascending)
```

**Index 3: Delete Sync**
```
Collection: chat_messages
Fields:
  - source (Ascending)
  - deleted (Ascending)
  - deleteSyncedToTelegram (Ascending)
  - __name__ (Ascending)
```

**Index 4: Auto-Delete Query**
```
Collection: chat_messages
Fields:
  - timestamp (Ascending)
  - deleted (Ascending)
  - __name__ (Ascending)
```

**Index 5: Flutter Chat-Anzeige**
```
Collection: chat_messages
Fields:
  - deleted (Ascending)
  - timestamp (Descending)
  - __name__ (Ascending)
```

---

## 🔧 SCHRITT 4: FIRESTORE SECURITY RULES

**4.1 Security Rules konfigurieren:**

Gehe zur Firebase Console:

1. **Firestore Database** → **Rules** Tab
2. Füge folgende Rules ein:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat-Nachrichten Collection
    match /chat_messages/{messageId} {
      // Lesen: Alle authentifizierten Nutzer
      allow read: if request.auth != null;
      
      // Schreiben: Alle authentifizierten Nutzer
      allow create: if request.auth != null;
      
      // Update: Nur eigene Nachrichten (app-source) oder Daemon
      allow update: if request.auth != null && (
        resource.data.appUserId == request.auth.uid ||
        resource.data.source == 'telegram'  // Daemon-Updates
      );
      
      // Löschen: Nur eigene Nachrichten
      allow delete: if request.auth != null && 
        resource.data.appUserId == request.auth.uid;
    }
  }
}
```

**Für Entwicklung (weniger restriktiv):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /chat_messages/{messageId} {
      allow read, write: if true;
    }
  }
}
```

---

## 🔧 SCHRITT 5: DAEMON STARTEN

**5.1 Erstmaliger Start (Session-Login):**

```bash
cd /home/user/flutter_app/scripts
python3 telegram_chat_sync_daemon.py
```

**Beim ersten Start:**
1. Pyrogram fordert deine Telefonnummer an → Eingeben und Enter
2. Telegram sendet dir einen Code → Code eingeben und Enter
3. Falls 2FA aktiv: Passwort eingeben
4. Session wird gespeichert in `weltenbibliothek_chat_sync.session`

**5.2 Dauerhafter Betrieb (mit systemd):**

**Service-Datei erstellen:**

```bash
sudo nano /etc/systemd/system/telegram-chat-sync.service
```

**Inhalt:**

```ini
[Unit]
Description=Telegram Chat Sync Daemon (Weltenbibliothek)
After=network.target

[Service]
Type=simple
User=dein_username
WorkingDirectory=/home/user/flutter_app/scripts
ExecStart=/usr/bin/python3 /home/user/flutter_app/scripts/telegram_chat_sync_daemon.py
Restart=always
RestartSec=10

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
journalctl -u telegram-chat-sync.service -f  # Logs anzeigen
```

**5.3 Alternativer Betrieb (screen/tmux):**

```bash
# Mit screen
screen -S telegram-sync
cd /home/user/flutter_app/scripts
python3 telegram_chat_sync_daemon.py
# Strg+A, dann D zum Detachen

# Mit tmux
tmux new -s telegram-sync
cd /home/user/flutter_app/scripts
python3 telegram_chat_sync_daemon.py
# Strg+B, dann D zum Detachen
```

---

## 🔧 SCHRITT 6: HTTP-PROXY STARTEN (Falls noch nicht aktiv)

Der HTTP-Proxy macht FTP-Dateien für Flutter zugänglich:

```bash
cd /home/user/flutter_app/scripts
python3 simple_http_server.py
```

**Dauerhafter Betrieb (systemd):**

```bash
sudo nano /etc/systemd/system/ftp-http-proxy.service
```

```ini
[Unit]
Description=FTP HTTP Proxy Server (Port 8080)
After=network.target

[Service]
Type=simple
User=dein_username
WorkingDirectory=/home/user/flutter_app/scripts
ExecStart=/usr/bin/python3 /home/user/flutter_app/scripts/simple_http_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable ftp-http-proxy.service
sudo systemctl start ftp-http-proxy.service
```

---

## 🔧 SCHRITT 7: FLUTTER-APP AKTUALISIEREN

**7.1 Chat-Service in main.dart initialisieren:**

Öffne `lib/main.dart` und füge hinzu:

```dart
import 'services/chat_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ Chat-Service initialisieren
  await ChatSyncService().initialize();
  
  runApp(const MyApp());
}
```

**7.2 Chat-Screen in Navigation einbinden:**

In `lib/screens/home_screen.dart` (oder deinem Hauptmenü):

```dart
import 'telegram_chat_screen.dart';

// Navigation zum Chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TelegramChatScreen(),
  ),
);
```

**7.3 Dependencies überprüfen:**

Stelle sicher, dass `pubspec.yaml` folgendes enthält:

```yaml
dependencies:
  firebase_core: 3.6.0
  cloud_firestore: 5.4.3
  intl: ^0.19.0
```

Dann:

```bash
cd /home/user/flutter_app
flutter pub get
```

---

## ✅ SCHRITT 8: TESTEN

**8.1 Daemon-Status prüfen:**

```bash
# Via systemd
sudo systemctl status telegram-chat-sync.service

# Via logs
tail -f /var/log/telegram-chat-sync.log  # Falls logging konfiguriert
```

**8.2 Test-Szenarien:**

**Test 1: App → Telegram**
1. Öffne Flutter-App
2. Gehe zum Telegram Chat Screen
3. Schreibe eine Nachricht: "Test von App"
4. Öffne Telegram auf deinem Handy
5. Gehe zu @Weltenbibliothekchat
6. ✅ Nachricht sollte dort erscheinen

**Test 2: Telegram → App**
1. Öffne Telegram auf deinem Handy
2. Schreibe in @Weltenbibliothekchat: "Test von Telegram"
3. Öffne Flutter-App
4. ✅ Nachricht sollte in der App erscheinen

**Test 3: Bearbeitung synchronisieren**
1. Schreibe eine Nachricht in der App
2. Halte die Nachricht gedrückt → "Bearbeiten"
3. Ändere den Text
4. ✅ Änderung sollte in Telegram erscheinen

**Test 4: Löschung synchronisieren**
1. Schreibe eine Nachricht in der App
2. Halte die Nachricht gedrückt → "Löschen"
3. ✅ Nachricht sollte aus Telegram verschwinden

**Test 5: Medien-Upload**
1. Sende ein Foto in Telegram-Chat
2. ✅ Foto sollte in App erscheinen
3. ✅ Foto sollte auf FTP-Server hochgeladen sein (`/chat_media/`)

**Test 6: Auto-Delete (24h)**
1. Warte 24 Stunden nach Nachricht
2. ✅ Nachricht sollte automatisch gelöscht werden
3. Für Test: Setze `DELETE_AFTER_HOURS = 0.1` (6 Minuten)

---

## 🔍 TROUBLESHOOTING

### Problem: "No Firebase App '[DEFAULT]' has been created"

**Lösung:**
- Stelle sicher, dass `Firebase.initializeApp()` in `main.dart` VOR allen Firebase-Operationen aufgerufen wird
- Verwende `DefaultFirebaseOptions.currentPlatform`
- Stelle sicher, dass `firebase_options.dart` existiert

### Problem: "FloodWaitError: Too many requests"

**Lösung:**
- Pyrogram Rate-Limiting aktiv
- Warte die angegebene Zeit (z.B. 60 Sekunden)
- Reduziere Nachrichtenfrequenz

### Problem: Daemon startet nicht ("API_ID" oder "API_HASH" ungültig)

**Lösung:**
- Überprüfe Credentials in `telegram_chat_sync_daemon.py`
- API_ID muss numerisch sein (ohne Anführungszeichen im Code, aber als String)
- API_HASH muss exakt kopiert sein
- Erstelle ggf. neue App unter https://my.telegram.org/apps

### Problem: Nachrichten erscheinen nicht in Telegram

**Ursache:** `chat_id` nicht ermittelt

**Lösung:**
1. Sende ZUERST eine Nachricht in Telegram-Chat
2. Daemon erkennt Chat-ID automatisch
3. Dann funktionieren App → Telegram Nachrichten

### Problem: Firestore Index Fehler

**Fehlermeldung:** "The query requires an index"

**Lösung:**
- Klicke auf den Link in der Fehlermeldung
- Firebase erstellt Index automatisch
- Warte 1-2 Minuten bis Index aktiv ist
- Versuche erneut

### Problem: Medien werden nicht angezeigt

**Lösung:**
1. Prüfe ob HTTP-Proxy läuft: `curl http://Weltenbibliothek.ddns.net:8080`
2. Prüfe FTP-Zugriff: `ftp Weltenbibliothek.ddns.net`
3. Prüfe Firewall-Regeln (Port 8080 öffnen)
4. Prüfe FTP-Pfade in Firestore (`mediaUrl` sollte HTTP-URL sein)

### Problem: "Session file is corrupted"

**Lösung:**
```bash
cd /home/user/flutter_app/scripts
rm weltenbibliothek_chat_sync.session
python3 telegram_chat_sync_daemon.py  # Neu einloggen
```

---

## 📊 FIRESTORE DOKUMENT-STRUKTUR

**Collection:** `chat_messages`

**Dokument-Felder:**

```javascript
{
  // Basis-Informationen
  "messageId": "abc123",            // Eindeutige Nachricht-ID
  "text": "Hallo Welt!",            // Nachrichtentext
  "timestamp": Timestamp,           // Erstellungszeit
  
  // Quelle
  "source": "telegram",             // "telegram" oder "app"
  
  // Status-Flags
  "edited": false,                  // Wurde bearbeitet?
  "deleted": false,                 // Wurde gelöscht?
  
  // Telegram-Benutzer (falls source="telegram")
  "telegramUserId": "123456789",
  "telegramUsername": "maxmuster",
  "telegramFirstName": "Max",
  "telegramLastName": "Muster",
  
  // App-Benutzer (falls source="app")
  "appUserId": "app_user_001",
  "appUsername": "FlutterUser",
  
  // Medien
  "mediaUrl": "http://...8080/chat_media/photo_123.jpg",
  "mediaType": "photo",             // "photo", "video", "audio", "document"
  "ftpPath": "/chat_media/photo_123.jpg",
  
  // Reply
  "replyToId": "def456",            // ID der Nachricht auf die geantwortet wird
  
  // Sync-Status
  "syncedToTelegram": true,         // App → Telegram erfolgreich?
  "telegramMessageId": "789",       // Telegram-interne Message-ID
  "syncedAt": Timestamp,
  
  // Edit-Sync
  "editSyncedToTelegram": true,
  "editedAt": Timestamp,
  "editSyncedAt": Timestamp,
  
  // Delete-Sync
  "deleteSyncedToTelegram": true,
  "deletedAt": Timestamp,
  "deleteSyncedAt": Timestamp,
  
  // Auto-Delete Flag
  "autoDeleted": false,             // Wurde automatisch gelöscht?
}
```

---

## 🎯 ZUSAMMENFASSUNG

**Was wurde implementiert:**

✅ **Python-Daemon** (`scripts/telegram_chat_sync_daemon.py`)
- Telegram ↔ Firestore bidirektionale Synchronisation
- Auto-Delete nach 24 Stunden
- Medien-Upload zu FTP-Server
- Edit & Delete Sync

✅ **Flutter Service** (`lib/services/chat_sync_service.dart`)
- Nachrichten senden/empfangen
- Bearbeiten/Löschen
- Real-time Firestore Listener
- ChatMessage Model

✅ **Flutter UI** (`lib/screens/telegram_chat_screen.dart`)
- Chat-Interface mit Nachrichtenblasen
- Edit/Delete Funktionen
- Reply-Funktion
- Medien-Vorschau

✅ **FTP-Integration** (bereits vorhanden)
- `simple_http_server.py` für HTTP-Zugriff
- Xlight FTP Server für physische Speicherung

**Nächste Schritte:**

1. ✅ Telegram API Credentials besorgen
2. ✅ Python-Daemon konfigurieren und starten
3. ✅ Firestore Indexes erstellen
4. ✅ Flutter-App testen
5. ✅ Systemd-Services für dauerhaften Betrieb einrichten

**Support:**

Bei Fragen oder Problemen:
- Überprüfe Daemon-Logs: `journalctl -u telegram-chat-sync.service -f`
- Überprüfe Firestore-Konsole auf Fehler
- Teste FTP/HTTP-Zugriff manuell
- Überprüfe Firebase Security Rules

---

**🎉 Viel Erfolg mit der bidirektionalen Telegram-Chat-Synchronisation!**
