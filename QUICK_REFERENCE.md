# 🚀 Weltenbibliothek v3.0.0+88 - Quick Reference

## 📱 Schnell-Zugriff: Die wichtigsten Informationen

---

## 🔗 APK Download

**[⬇️ APK herunterladen (66 MB)](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=781a9c41-1ab2-4aab-b51f-4751d39f7875&file_path=%2Fhome%2Fuser%2FWeltenbibliothek_v3.0.0%2B88_Release.apk&file_name=Weltenbibliothek_v3.0.0+88_Release.apk)**

**Version:** 3.0.0+88  
**Größe:** 66 MB  
**Datum:** 2025-06-09  
**Status:** ✅ Produktionsbereit

---

## ⚡ 3-Minuten-Setup

### Schritt 1: APK installieren (30 Sekunden)
```bash
# APK auf Android-Gerät übertragen und installieren
# (via USB, Email, Cloud)
```

### Schritt 2: Backend-Daemon installieren (1 Minute)
```bash
cd /home/user/flutter_app/scripts
sudo ./install_daemon.sh
```

### Schritt 3: Firestore-Indexes (1 Minute)
```bash
# Indexes-Info anzeigen
python3 show_firestore_indexes.py

# Dann manuell erstellen oder automatisch via Fehler-URLs
```

### Schritt 4: Test (30 Sekunden)
```bash
# App öffnen → Chat → Nachricht senden
# Telegram prüfen: https://t.me/Weltenbibliothekchat
```

---

## 📋 Wichtige Befehle

### Daemon-Management
```bash
# Status prüfen
sudo systemctl status telegram-chat-sync

# Logs anzeigen (Live)
tail -f /var/log/telegram-chat-sync.log

# Neustart
sudo systemctl restart telegram-chat-sync

# Stoppen
sudo systemctl stop telegram-chat-sync

# Deaktivieren
sudo systemctl disable telegram-chat-sync
```

### Troubleshooting
```bash
# Daemon-Prozess prüfen
ps aux | grep telegram_chat_sync

# Firestore-Indexes prüfen
python3 scripts/show_firestore_indexes.py

# FTP-Verbindung testen
ftp Weltenbibliothek.ddns.net
# User: Weltenbibliothek
# Pass: Jolene2305

# HTTP-Proxy testen
curl -I http://Weltenbibliothek.ddns.net:8080/
```

---

## 🔑 Credentials (Development-Mode)

### Telegram API
```
API_ID: 25697241
API_HASH: 19cfb3819684da4571a91874ee22603a
Chat ID: -1001191136317
Chat: @Weltenbibliothekchat
```

### FTP-Server
```
Host: Weltenbibliothek.ddns.net
Port: 21
User: Weltenbibliothek
Pass: Jolene2305
Path: /chat_media/
```

### Firebase
```
Project: weltenbibliothek-5d21f
Console: https://console.firebase.google.com/project/weltenbibliothek-5d21f
Admin SDK: /opt/flutter/firebase-admin-sdk.json
google-services.json: android/app/google-services.json
```

---

## 📊 System-Status prüfen

### ✅ Alles funktioniert wenn:

**Daemon:**
```bash
sudo systemctl status telegram-chat-sync
# Active: active (running) ✓
```

**Logs:**
```bash
tail -n 20 /var/log/telegram-chat-sync.log
# ✅ MadelineProto verbunden
# ✅ Chat ID: -1001191136317
# 🔄 SYNC CYCLE #X
```

**Firestore:**
- Firebase Console → Indexes → Alle 5 Indexes: "Enabled" ✓

**FTP:**
```bash
curl -I http://Weltenbibliothek.ddns.net:8080/
# HTTP/1.0 200 OK ✓
```

---

## 🐛 Häufige Probleme & Lösungen

### Problem: Daemon startet nicht
```bash
# PHP-Version prüfen (muss >= 8.1 sein)
php -v

# MadelineProto prüfen
ls -la /home/user/madeline_backend/vendor

# Logs prüfen
tail -f /var/log/telegram-chat-sync.log
```

### Problem: Keine Synchronisation
```bash
# Firestore-Indexes prüfen (alle 5 müssen "Enabled" sein)
python3 scripts/show_firestore_indexes.py

# Daemon-Logs prüfen
tail -f /var/log/telegram-chat-sync.log
```

### Problem: Medien werden nicht angezeigt
```bash
# HTTP-Proxy prüfen
curl -I http://Weltenbibliothek.ddns.net:8080/

# FTP-Verbindung testen
ftp Weltenbibliothek.ddns.net
```

---

## 📚 Vollständige Dokumentation

**Deployment:**
- `DEPLOYMENT_GUIDE.md` - Komplette Installation & Konfiguration (16 KB)

**Testing:**
- `TESTING_GUIDE.md` - 15 Test-Cases mit Checklisten (16 KB)

**Projekt-Übergabe:**
- `FINALE_UEBERGABE_v3.0.0+88.md` - Vollständige Projekt-Dokumentation (25 KB)

**Build-Info:**
- `BUILD_INFO_v3.0.0+88.md` - Versions-Details & Changelog (8 KB)

---

## 🔗 Nützliche Links

**Firebase Console:**
- Projekt: https://console.firebase.google.com/project/weltenbibliothek-5d21f
- Firestore: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore
- Indexes: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes

**Telegram:**
- Chat: https://t.me/Weltenbibliothekchat
- Web: https://web.telegram.org

**APK Download:**
- https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=781a9c41-1ab2-4aab-b51f-4751d39f7875&file_path=%2Fhome%2Fuser%2FWeltenbibliothek_v3.0.0%2B88_Release.apk&file_name=Weltenbibliothek_v3.0.0+88_Release.apk

---

## 📞 Support

**Bei Fragen:**
1. Prüfen Sie `DEPLOYMENT_GUIDE.md` (16 KB)
2. Prüfen Sie `TESTING_GUIDE.md` (16 KB)
3. Prüfen Sie Daemon-Logs: `tail -f /var/log/telegram-chat-sync.log`
4. Kontaktieren Sie den Support (siehe FINALE_UEBERGABE.md)

---

**Letzte Aktualisierung:** 2025-06-09  
**Status:** ✅ Produktionsbereit
