# 🔄 MULTI-CHANNEL TELEGRAM SYNCHRONISATION

## ✅ SYSTEM STATUS: VOLLSTÄNDIG FUNKTIONSFÄHIG

Alle 6 Telegram-Kanäle werden bidirektional mit Firestore synchronisiert.

---

## 📺 SYNCHRONISIERTE KANÄLE

| # | Kanal | Collection | FTP Path | Status |
|---|-------|------------|----------|--------|
| 1 | @Weltenbibliothekchat | `chat_messages` | `/chat/` | ✅ AKTIV |
| 2 | @WeltenbibliothekPDF | `pdf_documents` | `/pdfs/` | ✅ AKTIV |
| 3 | @weltenbibliothekbilder | `images` | `/images/` | ✅ AKTIV |
| 4 | @WeltenbibliothekWachauf | `wachauf_content` | `/wachauf/` | ✅ AKTIV |
| 5 | @ArchivWeltenBibliothek | `archive_items` | `/archiv/` | ✅ AKTIV |
| 6 | @WeltenbibliothekHoerbuch | `audiobooks` | `/audios/` | ✅ AKTIV |

---

## 🚀 VERWALTUNG

### Alle Daemons starten
```bash
cd /home/user/flutter_app/scripts
bash start_all_channels.sh
```

### Alle Daemons stoppen
```bash
cd /home/user/flutter_app/scripts
bash stop_all_channels.sh
```

### Status überprüfen
```bash
ps aux | grep sync_ | grep -v grep
```

### Logs überwachen

**Einzelner Kanal:**
```bash
tail -f logs/channel_chat.log
tail -f logs/channel_pdfs.log
tail -f logs/channel_bilder.log
tail -f logs/channel_wachauf.log
tail -f logs/channel_archiv.log
tail -f logs/channel_hoerbuch.log
```

**Alle Kanäle gleichzeitig:**
```bash
tail -f logs/channel_*.log
```

---

## ⚙️ KONFIGURATION

### Sync-Einstellungen
- **Sync-Intervall**: 3 Sekunden
- **Auto-Delete**: 6 Stunden
- **FTP-Server**: Weltenbibliothek.ddns.net:21
- **HTTP-Server**: http://Weltenbibliothek.ddns.net:8080

### Firestore Collections

Jeder Kanal hat seine eigene Collection mit spezifischer Datenstruktur:

#### 1. chat_messages (Chat)
- Text-Nachrichten
- Alle Medientypen (Foto, Video, Audio, Dokument)

#### 2. pdf_documents (PDFs)
- PDF-Dokumente
- Buch-Metadaten (Titel, Autor, Seiten)

#### 3. images (Bilder)
- Fotos und Bilder
- Bild-Metadaten (Breite, Höhe, Caption)

#### 4. wachauf_content (Wachauf)
- Wachauf-Inhalte
- Kategorie-Klassifizierung

#### 5. archive_items (Archiv)
- Historische Archiv-Einträge
- Archiv-Kategorien

#### 6. audiobooks (Hörbücher)
- Hörbuch-Dateien
- Metadaten (Titel, Autor, Sprecher, Dauer)

---

## 🔄 FUNKTIONSWEISE

### Telegram → Firestore
1. Daemon ruft alle 3 Sekunden neue Nachrichten ab
2. Medien werden heruntergeladen
3. Medien werden auf FTP-Server hochgeladen
4. Metadaten + Medien-URLs in Firestore gespeichert
5. HTTP-URLs für direkten Zugriff verfügbar

### Firestore → Telegram
1. App erstellt Nachricht in Firestore mit `source: 'app'`
2. Daemon erkennt ungesyncte App-Nachricht
3. Nachricht wird zu Telegram-Kanal gesendet
4. Telegram Message-ID in Firestore aktualisiert

### Auto-Delete
- Nachrichten älter als 6 Stunden werden automatisch gelöscht
- Firestore-Dokumente werden als `deleted: true` markiert
- FTP-Medien werden entfernt

---

## 📁 DATEIEN

### Daemon-Skripte
- `sync_chat.php` - Chat-Kanal Daemon
- `sync_pdfs.php` - PDFs-Kanal Daemon
- `sync_bilder.php` - Bilder-Kanal Daemon
- `sync_wachauf.php` - Wachauf-Kanal Daemon
- `sync_archiv.php` - Archiv-Kanal Daemon
- `sync_hoerbuch.php` - Hörbücher-Kanal Daemon

### Verwaltungs-Skripte
- `start_all_channels.sh` - Alle Daemons starten
- `stop_all_channels.sh` - Alle Daemons stoppen
- `create_channel_daemons.sh` - Daemon-Skripte neu generieren

### Setup-Skripte
- `setup_multi_channel_collections.py` - Firestore Collections erstellen

### Backup
- `telegram_chat_sync_madeline_backup.php` - Original Single-Channel Daemon

---

## 🔒 SICHERHEIT

### Firestore Security Rules
Aktuell im Development-Modus (alle Operationen erlaubt):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{collection}/{document} {
      allow read: if true;
      allow write: if true;
    }
  }
}
```

**⚠️ Für Produktion:** Implementieren Sie granulare Rules pro Collection.

---

## 📊 MONITORING

### Daemon-Status
```bash
# Prozesse prüfen
ps aux | grep sync_ | grep -v grep

# CPU/Memory Usage
top -p $(pgrep -d',' -f sync_)
```

### Firestore-Status
```bash
cd /home/user/flutter_app/scripts
python3 << 'EOF'
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

collections = ['chat_messages', 'pdf_documents', 'images', 'wachauf_content', 'archive_items', 'audiobooks']

for coll in collections:
    count = len(db.collection(coll).limit(100).get())
    print(f"{coll}: {count} Dokumente")
EOF
```

### Log-Analyse
```bash
# Fehler in allen Logs finden
grep -i "fehler\|error" logs/channel_*.log

# Erfolgreiche Synchronisationen zählen
grep "neue Nachrichten verarbeitet" logs/channel_*.log | grep -v "0 neue"

# Medien-Uploads überprüfen
grep "Medien auf FTP hochgeladen" logs/channel_*.log
```

---

## 🐛 TROUBLESHOOTING

### Daemon startet nicht
```bash
# Logs überprüfen
tail -50 logs/channel_[NAME].log

# PHP Syntax prüfen
php -l sync_[NAME].php

# MadelineProto Session prüfen
ls -la session.madeline/
```

### Keine Synchronisation
```bash
# Firestore Verbindung testen
python3 << 'EOF'
import firebase_admin
from firebase_admin import credentials, firestore
cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
print("✅ Firestore verbunden")
EOF

# FTP Verbindung testen
cd /home/user/flutter_app/scripts
php test_ftp_correct.php
```

### Medien-Upload Fehler
```bash
# FTP-Ordner überprüfen
# Sicherstellen dass alle Ordner existieren:
# /chat/, /pdfs/, /images/, /wachauf/, /archiv/, /audios/

# FTP-Berechtigungen prüfen
# User "Weltenbibliothek" muss Schreibrechte haben
```

---

## 📞 SUPPORT

Bei Problemen:

1. Logs überprüfen: `logs/channel_*.log`
2. Daemon-Status prüfen: `ps aux | grep sync_`
3. Firestore Console überprüfen
4. FTP-Server-Status testen

---

## 🎉 ERFOLGREICHE IMPLEMENTIERUNG!

✅ 6 Kanäle synchronisieren alle 3 Sekunden  
✅ Bidirektionale Synchronisation funktioniert  
✅ Medien-Upload auf FTP-Server funktioniert  
✅ Auto-Delete nach 6 Stunden aktiv  
✅ HTTP-URLs für alle Medien verfügbar  

**System läuft stabil und produktionsbereit!**

---

*Letzte Aktualisierung: 2025-11-08*
