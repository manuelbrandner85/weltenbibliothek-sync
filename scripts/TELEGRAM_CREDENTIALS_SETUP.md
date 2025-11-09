# 🔐 TELEGRAM API CREDENTIALS SETUP

## ⚠️ WICHTIG: Einmalige Einrichtung erforderlich!

Bevor Sie den Chat-Sync-Daemon starten können, müssen Sie einmalig Ihre Telegram API Credentials konfigurieren.

---

## 📋 SCHRITT 1: API CREDENTIALS BESORGEN

Falls Sie noch keine Telegram API Credentials haben:

1. **Gehe zu:** https://my.telegram.org/apps
2. **Melde dich an** mit deiner Telegram-Telefonnummer
3. **Erstelle neue App:**
   - App title: `Weltenbibliothek Chat Sync`
   - Short name: `weltenbib_sync`
   - Platform: `Other`
4. **Kopiere folgende Werte:**
   - **API ID** (numerisch, z.B. `12345678`)
   - **API Hash** (alphanumerisch, z.B. `0123456789abcdef1234567890abcdef`)

---

## 🔧 SCHRITT 2: INTERAKTIVES SETUP AUSFÜHREN

Führen Sie das Setup-Script aus:

```bash
cd /home/user/flutter_app/scripts
python3 setup_telegram_credentials.py
```

**Das Script fragt Sie nach:**
1. API ID (die numerische ID von my.telegram.org)
2. API Hash (der lange alphanumerische Key)
3. Telefonnummer (im internationalen Format, z.B. `+43XXXXXXXXXX`)

**Beispiel-Ausgabe:**
```
============================================================
🔐 TELEGRAM API CREDENTIALS SETUP
============================================================

📋 Dieses Script speichert Ihre Telegram API Credentials sicher.

🔗 Falls Sie noch keine API Credentials haben:
   1. Gehe zu: https://my.telegram.org/apps
   ...

============================================================

📝 Schritt 1/3: API ID
   (Numerisch, z.B. 12345678)
   API ID: 12345678

📝 Schritt 2/3: API Hash
   (Alphanumerisch, z.B. 0123456789abcdef...)
   API Hash: 0123456789abcdef1234567890abcdef

📝 Schritt 3/3: Telefonnummer
   (Internationales Format, z.B. +43XXXXXXXXXX)
   Telefonnummer: +43XXXXXXXXXX

============================================================
✅ CREDENTIALS ERFOLGREICH GESPEICHERT!
============================================================
```

---

## 📁 SCHRITT 3: CONFIG-DATEI ÜBERPRÜFEN

Nach erfolgreichem Setup wurde die Datei `telegram_config.json` erstellt:

```bash
cd /home/user/flutter_app/scripts
cat telegram_config.json
```

**Erwarteter Inhalt:**
```json
{
  "api_id": 12345678,
  "api_hash": "0123456789abcdef1234567890abcdef",
  "phone_number": "+43XXXXXXXXXX"
}
```

---

## 🚀 SCHRITT 4: DAEMON STARTEN

Jetzt können Sie den Chat-Sync-Daemon starten:

```bash
cd /home/user/flutter_app/scripts
python3 telegram_chat_sync_daemon.py
```

**Beim ersten Start:**
- Falls keine Session vorhanden: Telegram sendet Ihnen einen Code
- Geben Sie den Code ein
- Falls 2FA aktiv: Geben Sie Ihr Passwort ein
- Session wird gespeichert in `weltenbibliothek_session.session`

**Bei folgenden Starts:**
- Session wird automatisch geladen
- Kein Login erforderlich

---

## ✅ TROUBLESHOOTING

### Problem: "Config-Datei nicht gefunden"

**Fehler:**
```
❌ Config-Datei nicht gefunden: telegram_config.json
📋 Bitte führen Sie zuerst aus: python3 setup_telegram_credentials.py
```

**Lösung:**
```bash
cd /home/user/flutter_app/scripts
python3 setup_telegram_credentials.py
```

---

### Problem: "API ID muss numerisch sein"

**Fehler beim Setup:**
```
❌ Fehler: API ID muss numerisch sein!
```

**Lösung:**
- API ID sollte nur Zahlen enthalten (z.B. `12345678`)
- Keine Buchstaben, keine Leerzeichen, keine Sonderzeichen
- Kopieren Sie die ID direkt von my.telegram.org/apps

---

### Problem: "API Hash zu kurz"

**Fehler beim Setup:**
```
❌ Fehler: API Hash zu kurz! Sollte ca. 32 Zeichen lang sein.
```

**Lösung:**
- API Hash sollte ca. 32 Zeichen lang sein
- Kopieren Sie den kompletten Hash von my.telegram.org/apps
- Achten Sie darauf, dass Sie den kompletten String kopiert haben

---

### Problem: "Telefonnummer muss mit + beginnen"

**Fehler beim Setup:**
```
❌ Fehler: Telefonnummer muss mit + beginnen (international)!
```

**Lösung:**
- Verwenden Sie das internationale Format
- **Richtig:** `+43XXXXXXXXXX` (Österreich)
- **Falsch:** `0XXXXXXXXXX`
- **Falsch:** `43XXXXXXXXXX`

---

### Problem: "The API key is required for new authorizations"

**Fehler beim Daemon-Start:**
```
❌ Fataler Fehler: The API key is required for new authorizations.
```

**Lösung:**
1. Prüfen Sie ob `telegram_config.json` existiert:
   ```bash
   ls -l telegram_config.json
   ```

2. Falls Datei fehlt:
   ```bash
   python3 setup_telegram_credentials.py
   ```

3. Falls Datei vorhanden, prüfen Sie Inhalt:
   ```bash
   cat telegram_config.json
   ```

4. Stellen Sie sicher, dass alle 3 Felder ausgefüllt sind

---

### Problem: Config überschreiben

**Sie möchten neue Credentials eingeben:**

```bash
cd /home/user/flutter_app/scripts
python3 setup_telegram_credentials.py
```

Wenn gefragt:
```
⚠️  Config-Datei gefunden: telegram_config.json
   Möchten Sie die vorhandenen Credentials überschreiben? (j/n): j
```

Geben Sie `j` ein um zu überschreiben.

---

## 🔒 SICHERHEIT

**⚠️ WICHTIG:**
- `telegram_config.json` enthält sensible Daten!
- **NICHT** in Git/GitHub committen!
- **NICHT** öffentlich teilen!

**Bereits in .gitignore:**
```
telegram_config.json
*.session
```

---

## 📖 WEITERE DOKUMENTATION

**Nach erfolgreichem Setup:**
- Folgen Sie der Checkliste: `TELEGRAM_CHAT_SETUP_CHECKLISTE.md`
- Vollständige Anleitung: `TELEGRAM_CHAT_SYNC_ANLEITUNG.md`
- Status-Übersicht: `TELEGRAM_CHAT_INTEGRATION_STATUS.md`

---

## ✅ SETUP ABGESCHLOSSEN

**Wenn Sie bis hierher alles durchgeführt haben:**

✅ `telegram_config.json` existiert  
✅ Enthält API_ID, API_HASH, PHONE_NUMBER  
✅ Daemon kann gestartet werden

**Nächster Schritt:**
```bash
python3 telegram_chat_sync_daemon.py
```

🎉 **Viel Erfolg!**
