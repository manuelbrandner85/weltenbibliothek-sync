# 🧪 Weltenbibliothek - Live-Testing-Anleitung

## 📱 Bidirektionale Telegram-Chat-Synchronisation

**Version:** 3.0.0+88  
**Test-Datum:** 2025-06-09  
**Status:** Bereit für Live-Tests

---

## 🎯 Test-Ziele

Diese Anleitung führt durch systematische Tests der **bidirektionalen Synchronisation** zwischen Flutter-App und Telegram-Kanal **@Weltenbibliothekchat**.

**Getestete Funktionen:**
1. ✅ App → Telegram (Nachrichten senden)
2. ✅ Telegram → App (Nachrichten empfangen)
3. ✅ Bearbeitung synchronisieren (bidirektional)
4. ✅ Löschung synchronisieren (bidirektional)
5. ✅ Medien-Upload (Bilder/Videos/Dateien)
6. ✅ Benutzer-Display (Telegram-Usernamen)
7. ✅ Auto-Delete (24h Cleanup)
8. ✅ Echtzeit-Performance (Sync-Latenz)

---

## 🔧 Vorbereitung

### Voraussetzungen

**Hardware:**
- ✅ Android-Gerät mit installierter Weltenbibliothek-App (v3.0.0+88)
- ✅ Zweites Gerät/Browser für Telegram-Zugriff (https://web.telegram.org)

**Software:**
- ✅ Chat-Sync-Daemon läuft (PHP-Backend)
- ✅ Firestore-Indexes erstellt (alle 5 Indexes aktiv)
- ✅ HTTP-Proxy läuft (Port 8080 für Medien)
- ✅ Internet-Verbindung stabil

**Accounts:**
- ✅ Telegram-Account mit Zugriff auf @Weltenbibliothekchat
- ✅ Firebase-Account mit ausreichenden Quotas

### Daemon-Status prüfen

```bash
# systemd-Service-Status
sudo systemctl status telegram-chat-sync.service

# Sollte zeigen:
#   Active: active (running)
#   Main PID: <PID>

# Logs prüfen
tail -n 50 /var/log/telegram-chat-sync.log

# Erwartete Ausgabe:
#   ✅ MadelineProto verbunden
#   ✅ Chat ID: -1001191136317
#   🔄 SYNC CYCLE #X - <Timestamp>
```

### Firestore-Indexes prüfen

**Firebase Console:**  
https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes

**Erwartung:** Alle 5 Indexes im Status **"Enabled"** (grüner Haken)

---

## 📝 Test-Protokoll

Dokumentieren Sie jeden Test mit diesem Format:

```
Test-ID: T01
Funktion: App → Telegram
Erwartung: Nachricht erscheint in Telegram nach ~5 Sek
Resultat: [✅ Bestanden | ❌ Fehlgeschlagen]
Notizen: [Besonderheiten, Fehler, Latenz]
Screenshot: [Optional]
```

---

## 🧪 Test-Cases

### Test 1: Basis-Kommunikation (App → Telegram)

**Ziel:** Verifizieren, dass Nachrichten aus der App in Telegram erscheinen

**Schritte:**
1. Flutter-App öffnen
2. Zum Chat navigieren (💬 Telegram Chat auf Startseite)
3. Text eingeben: `TEST_01: Hallo aus der App! [Timestamp]`
4. "Senden"-Button drücken
5. Telegram-App öffnen: https://t.me/Weltenbibliothekchat
6. Nach Nachricht suchen

**Erwartetes Verhalten:**
- ✅ Nachricht erscheint in App-Chat sofort
- ✅ Nachricht erscheint in Telegram nach **5-15 Sekunden**
- ✅ Sync-Status zeigt "✓✓" (doppeltes Häkchen)
- ✅ Telegram-Username wird angezeigt (z.B. "@username")

**Fehler-Diagnose:**
- **Nachricht erscheint nicht:** Daemon-Logs prüfen (siehe oben)
- **Latenz > 30 Sek:** Sync-Intervall zu lang (siehe DEPLOYMENT_GUIDE.md)
- **Keine Sync-Bestätigung:** Firestore-Schreibfehler (Permissions?)

---

### Test 2: Basis-Kommunikation (Telegram → App)

**Ziel:** Verifizieren, dass Telegram-Nachrichten in der App erscheinen

**Schritte:**
1. Telegram-App öffnen: https://t.me/Weltenbibliothekchat
2. Nachricht senden: `TEST_02: Hallo aus Telegram! [Timestamp]`
3. Flutter-App öffnen (Chat-Screen)
4. Nach unten scrollen (Pull-to-Refresh)

**Erwartetes Verhalten:**
- ✅ Nachricht erscheint in Telegram sofort
- ✅ Nachricht erscheint in App nach **5-15 Sekunden**
- ✅ Telegram-Username wird korrekt angezeigt
- ✅ Timestamp ist korrekt (UTC → Lokale Zeit)

**Fehler-Diagnose:**
- **Nachricht erscheint nicht:** Firestore-Index fehlt (siehe DEPLOYMENT_GUIDE.md)
- **Username fehlt:** MadelineProto-Session veraltet (neu authentifizieren)
- **Timestamp falsch:** Zeitzonen-Problem (Server-UTC vs. Lokal)

---

### Test 3: Nachricht bearbeiten (App → Telegram)

**Ziel:** Verifizieren, dass Edits aus der App in Telegram übernommen werden

**Schritte:**
1. In Flutter-App: Bestehende Nachricht **lange drücken** (Long-Press)
2. Menü-Option **"Bearbeiten"** wählen
3. Text ändern zu: `TEST_03: Bearbeitete Nachricht aus App [Timestamp]`
4. "Speichern" drücken
5. Telegram-App prüfen

**Erwartetes Verhalten:**
- ✅ In App: Nachricht zeigt "(bearbeitet)" Badge
- ✅ In Telegram: Nachricht ist aktualisiert nach **5-15 Sekunden**
- ✅ In Telegram: Telegram zeigt "edited" Label
- ✅ Edit-History ist konsistent

**Fehler-Diagnose:**
- **Edit erscheint nicht:** Firestore-Index "Edit Sync" fehlt
- **Doppelte Nachrichten:** Daemon sendet neue Nachricht statt Edit
- **Alte Nachricht bleibt:** Edit-Sync-Flag nicht gesetzt

---

### Test 4: Nachricht bearbeiten (Telegram → App)

**Ziel:** Verifizieren, dass Telegram-Edits in der App übernommen werden

**Schritte:**
1. In Telegram: Eigene Nachricht editieren (Pencil-Icon)
2. Text ändern zu: `TEST_04: Bearbeitet in Telegram [Timestamp]`
3. Flutter-App prüfen (Pull-to-Refresh)

**Erwartetes Verhalten:**
- ✅ In App: Nachricht wird aktualisiert nach **5-15 Sekunden**
- ✅ In App: "(bearbeitet)" Badge erscheint
- ✅ Timestamp wird nicht geändert (original bleibt)
- ✅ UI scrollt nicht automatisch (behält Position)

**Fehler-Diagnose:**
- **Edit erscheint nicht:** Daemon erkennt Edit-Event nicht
- **App crashed:** Null-Safety-Problem in ChatMessage.fromFirestore()
- **Falscher Text:** Daemon holt alte Version statt aktueller

---

### Test 5: Nachricht löschen (App → Telegram)

**Ziel:** Verifizieren, dass Löschungen aus der App in Telegram übernommen werden

**Schritte:**
1. In Flutter-App: Nachricht **lange drücken**
2. Menü-Option **"Löschen"** wählen
3. Bestätigen
4. Telegram-App prüfen

**Erwartetes Verhalten:**
- ✅ In App: Nachricht verschwindet sofort
- ✅ In Telegram: Nachricht wird gelöscht nach **5-15 Sekunden**
- ✅ Firestore: `deleted: true` Flag gesetzt
- ✅ Medien bleiben erhalten (erst nach 24h gelöscht)

**Fehler-Diagnose:**
- **Nachricht bleibt in Telegram:** Delete-Sync-Index fehlt
- **"Permission Denied" Fehler:** Telegram API-Limits (nur eigene Nachrichten löschbar)
- **App crashed:** Firestore-Listener nicht robust genug

---

### Test 6: Nachricht löschen (Telegram → App)

**Ziel:** Verifizieren, dass Telegram-Löschungen in der App übernommen werden

**Schritte:**
1. In Telegram: Eigene Nachricht löschen (Delete-Option)
2. Flutter-App prüfen (Pull-to-Refresh)

**Erwartetes Verhalten:**
- ✅ In App: Nachricht verschwindet nach **5-15 Sekunden**
- ✅ Firestore: `deleted: true` und `deletedFromTelegram: true`
- ✅ UI bleibt stabil (kein Flackern)

**Fehler-Diagnose:**
- **Nachricht bleibt in App:** Daemon erkennt Delete-Event nicht
- **App zeigt "Nachricht nicht gefunden":** Race Condition in Firestore
- **UI scrollt wild:** StreamBuilder reagiert zu aggressiv

---

### Test 7: Bild-Upload (App → Telegram)

**Ziel:** Verifizieren, dass Medien aus der App auf FTP hochgeladen und in Telegram angezeigt werden

**Schritte:**
1. In Flutter-App: **Kamera-Icon** im Chat drücken
2. "Galerie" wählen (oder Foto aufnehmen)
3. Bild auswählen
4. Optional: Text hinzufügen `TEST_07: Bild-Upload [Timestamp]`
5. "Senden" drücken
6. Telegram-App prüfen

**Erwartetes Verhalten:**
- ✅ In App: Bild-Preview erscheint sofort (lokales Caching)
- ✅ FTP: Bild wird hochgeladen (Dateiname: `chat_media_<timestamp>.jpg`)
- ✅ Firestore: `mediaUrl` Feld enthält HTTP-URL
- ✅ Telegram: Bild erscheint nach **10-20 Sekunden**
- ✅ Telegram: Bild ist herunterladbar und anzeigbar

**Fehler-Diagnose:**
- **Upload fehlgeschlagen:** FTP-Verbindung prüfen (siehe DEPLOYMENT_GUIDE.md)
- **Bild erscheint nicht in Telegram:** HTTP-Proxy läuft nicht (Port 8080)
- **"Invalid URL" Fehler:** Medien-URL falsch formatiert
- **Telegram zeigt Platzhalter:** Bildformat nicht unterstützt (PNG/JPG nur)

---

### Test 8: Video-Upload (App → Telegram)

**Ziel:** Verifizieren, dass Videos korrekt übertragen werden

**Schritte:**
1. In Flutter-App: Kamera-Icon → **Video** auswählen
2. Kurzes Video (5-10 Sek) aufnehmen oder aus Galerie wählen
3. "Senden" drücken
4. Telegram-App prüfen

**Erwartetes Verhalten:**
- ✅ FTP: Video wird hochgeladen (`.mp4` Format)
- ✅ Firestore: `mediaType: video` gesetzt
- ✅ Telegram: Video erscheint nach **20-60 Sekunden** (je nach Größe)
- ✅ Telegram: Video ist abspielbar

**Fehler-Diagnose:**
- **Upload Timeout:** Video zu groß (max 50 MB für FTP)
- **Telegram zeigt nicht an:** Codec nicht unterstützt (H.264 erforderlich)
- **App crashed:** Out-of-Memory bei großen Videos

---

### Test 9: Datei-Upload (Telegram → App)

**Ziel:** Verifizieren, dass Telegram-Datei-Uploads in der App angezeigt werden

**Schritte:**
1. In Telegram: Datei hochladen (PDF, DOCX, etc.)
2. Flutter-App prüfen

**Erwartetes Verhalten:**
- ✅ Daemon: Lädt Datei von Telegram herunter
- ✅ FTP: Datei wird hochgeladen
- ✅ Firestore: `mediaUrl` und `mediaType: file` gesetzt
- ✅ App: Datei-Link anzeigbar (Download-Button)

**Fehler-Diagnose:**
- **Datei fehlt:** Daemon unterstützt aktuell nur Bilder/Videos
- **"Unsupported Media Type":** Erweiterung der Media-Handler nötig

---

### Test 10: Antwort-Funktion (Reply)

**Ziel:** Verifizieren, dass Antworten (Thread-Struktur) synchronisiert werden

**Schritte:**
1. In Flutter-App: Nachricht lange drücken → **"Antworten"**
2. Antwort eingeben: `TEST_10: Dies ist eine Antwort [Timestamp]`
3. "Senden" drücken
4. Telegram-App prüfen

**Erwartetes Verhalten:**
- ✅ In App: Antwort zeigt Original-Nachricht als Quote
- ✅ Firestore: `replyToId` Feld gesetzt
- ✅ Telegram: Antwort erscheint als Reply nach **5-15 Sekunden**
- ✅ Telegram: Thread-Struktur erhalten

**Fehler-Diagnose:**
- **Reply-Kontext fehlt:** Daemon sendet als normale Nachricht
- **App zeigt falsches Original:** `replyToId` verweist auf falsche Nachricht
- **Telegram-API-Fehler:** Original-Nachricht zu alt (>48h)

---

### Test 11: Mehrere Benutzer (Multi-User-Chat)

**Ziel:** Verifizieren, dass mehrere Benutzer gleichzeitig chatten können

**Schritte:**
1. **Benutzer A:** Nachricht aus App senden
2. **Benutzer B:** Nachricht aus Telegram senden
3. **Benutzer A:** Antwort aus App
4. **Benutzer B:** Antwort aus Telegram
5. Beide Geräte prüfen

**Erwartetes Verhalten:**
- ✅ Alle Nachrichten erscheinen auf beiden Geräten
- ✅ Benutzer-Namen sind eindeutig (Telegram-Username vs. App-User-ID)
- ✅ Chronologische Reihenfolge korrekt
- ✅ Keine Nachrichten gehen verloren

**Fehler-Diagnose:**
- **Nachrichten überspringen:** Race Condition in Firestore-Writes
- **Falsche Reihenfolge:** Timestamp-Synchronisation-Problem
- **Duplicate Messages:** Daemon schreibt doppelt

---

### Test 12: Auto-Delete (24h Cleanup)

**Ziel:** Verifizieren, dass alte Nachrichten automatisch gelöscht werden

**Schritte:**
1. Nachricht mit Testzeit senden (oder Timer im Daemon anpassen)
2. 24 Stunden warten (oder Daemon-Timer auf 5 Min setzen für Schnelltest)
3. App und Telegram prüfen

**Daemon-Timer-Anpassung für Schnelltest:**
```php
// In telegram_chat_sync_madeline.php, Zeile ~200
$AGE_LIMIT_SECONDS = 300;  // 5 Minuten statt 86400 (24h)
```

**Erwartetes Verhalten:**
- ✅ Firestore: `deleted: true` Flag gesetzt
- ✅ FTP: Medien-Datei gelöscht
- ✅ App: Nachricht verschwindet beim nächsten Sync
- ✅ Telegram: Nachricht wird gelöscht

**Fehler-Diagnose:**
- **Nachrichten bleiben:** Auto-Delete-Index fehlt (siehe DEPLOYMENT_GUIDE.md)
- **FTP-Datei bleibt:** FTP-Delete-Operation fehlgeschlagen
- **Telegram-Delete-Fehler:** API-Limit (nur eigene Nachrichten löschbar)

---

### Test 13: Performance & Latenz

**Ziel:** Sync-Geschwindigkeit messen

**Schritte:**
1. Stopuhr bereithalten
2. Nachricht in App senden → **Timer starten**
3. Telegram-Ankunft messen → **Timer stoppen**
4. 10x wiederholen für Durchschnitt

**Erwartete Latenz:**
- ✅ App → Firestore: **< 1 Sekunde**
- ✅ Firestore → Daemon → Telegram: **5-15 Sekunden**
- ✅ Telegram → Daemon → Firestore: **5-15 Sekunden**
- ✅ Firestore → App: **< 2 Sekunden** (StreamBuilder Real-Time)

**Gesamt-Latenz App → Telegram:** **~10 Sekunden durchschnittlich**

**Performance-Optimierung:**
- Sync-Intervall reduzieren (siehe DEPLOYMENT_GUIDE.md)
- Firestore-Quotas erhöhen
- Daemon-Logging reduzieren (weniger I/O)

---

### Test 14: Fehlerbehandlung (Offline-Modus)

**Ziel:** Verifizieren, dass die App robust mit Netzwerkfehlern umgeht

**Schritte:**
1. Flutter-App öffnen (Online)
2. Flugmodus aktivieren
3. Nachricht senden
4. Flugmodus deaktivieren
5. App-Verhalten beobachten

**Erwartetes Verhalten:**
- ✅ App zeigt "Offline"-Indikator
- ✅ Nachricht bleibt in "Senden"-Queue (Pending-Status)
- ✅ Nach Reconnect: Nachricht wird automatisch gesendet
- ✅ Keine Duplicate Messages

**Fehler-Diagnose:**
- **App crashed:** Fehlende Null-Checks in Firestore-Calls
- **Nachricht verloren:** Keine lokale Queue-Implementierung
- **Duplicate Messages:** Retry-Logic ohne Duplikat-Check

---

### Test 15: Stress-Test (Hohe Last)

**Ziel:** System-Stabilität unter hoher Last testen

**Schritte:**
1. 50 Nachrichten schnell hintereinander senden (App + Telegram)
2. 10 Bilder gleichzeitig hochladen
3. Während Sync läuft: Nachrichten editieren/löschen
4. System-Verhalten beobachten

**Erwartetes Verhalten:**
- ✅ Alle Nachrichten werden verarbeitet (keine Verluste)
- ✅ Daemon bleibt stabil (kein Crash)
- ✅ Firestore-Quotas nicht überschritten
- ✅ FTP-Server bleibt erreichbar
- ✅ App-UI bleibt responsiv

**Fehler-Diagnose:**
- **Daemon crashed:** Memory Leak oder PHP-Timeout
- **Firestore-Quota-Fehler:** "Quota Exceeded" (Rate Limits)
- **FTP-Timeout:** Zu viele parallele Uploads
- **App-UI friert ein:** UI-Thread blockiert (Firestore-Queries zu groß)

---

## 📊 Ergebnis-Zusammenfassung

Nach Abschluss aller Tests:

### Test-Matrix

| Test-ID | Funktion | Status | Latenz | Notizen |
|---------|----------|--------|--------|---------|
| T01 | App → Telegram | ⏳ | - | - |
| T02 | Telegram → App | ⏳ | - | - |
| T03 | Edit (App → TG) | ⏳ | - | - |
| T04 | Edit (TG → App) | ⏳ | - | - |
| T05 | Delete (App → TG) | ⏳ | - | - |
| T06 | Delete (TG → App) | ⏳ | - | - |
| T07 | Bild-Upload | ⏳ | - | - |
| T08 | Video-Upload | ⏳ | - | - |
| T09 | Datei-Upload | ⏳ | - | - |
| T10 | Reply-Funktion | ⏳ | - | - |
| T11 | Multi-User | ⏳ | - | - |
| T12 | Auto-Delete | ⏳ | - | - |
| T13 | Performance | ⏳ | - | - |
| T14 | Offline-Modus | ⏳ | - | - |
| T15 | Stress-Test | ⏳ | - | - |

### Gesamtbewertung

**Status:** ⏳ Testing ausstehend  
**Kritische Fehler:** 0  
**Mittel-schwere Fehler:** 0  
**Kleinere Probleme:** 0  
**Durchschnittliche Latenz:** - Sek  
**System-Stabilität:** - / 10  
**Benutzerfreundlichkeit:** - / 10  

---

## 🐛 Bug-Tracking

### Bekannte Probleme (vor Testing)

| ID | Priorität | Beschreibung | Status | Lösung |
|----|-----------|--------------|--------|--------|
| - | - | - | - | - |

### Gefundene Bugs (während Testing)

| ID | Priorität | Beschreibung | Reproduktion | Status |
|----|-----------|--------------|--------------|--------|
| - | - | - | - | - |

---

## 📝 Empfehlungen nach Testing

*Wird nach Abschluss der Tests ausgefüllt*

**Performance-Verbesserungen:**
- ...

**Stability-Fixes:**
- ...

**UX-Optimierungen:**
- ...

**Sicherheits-Härtung:**
- ...

---

## ✅ Test-Abschluss-Checkliste

- [ ] Alle 15 Tests durchgeführt
- [ ] Test-Matrix ausgefüllt
- [ ] Bug-Liste erstellt
- [ ] Performance-Metriken dokumentiert
- [ ] Screenshots/Videos aufgenommen (optional)
- [ ] Empfehlungen formuliert
- [ ] Stakeholder informiert
- [ ] Production-Deployment freigegeben

---

**Viel Erfolg beim Testing! 🧪🚀**
