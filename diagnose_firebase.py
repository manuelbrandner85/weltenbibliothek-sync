#!/usr/bin/env python3
"""
Firebase Fehler-Diagnose Tool
Analysiert häufige Probleme und gibt Lösungen
"""

print("""
================================================================================
🔍 FIREBASE FEHLER-DIAGNOSE
================================================================================

Du hast die Rules gesetzt, aber die Fehler bleiben?
Hier sind die häufigsten Ursachen und Lösungen:

================================================================================
PROBLEM 1: Rules brauchen Zeit zum Aktivieren (30-60 Sekunden)
================================================================================

LÖSUNG:
1. Warte MINDESTENS 60 Sekunden nach dem Publish
2. Schließe die App KOMPLETT (nicht nur minimieren)
3. Lösche App-Cache: Einstellungen → Apps → Weltenbibliothek → Cache leeren
4. Starte die App NEU

⏱️  WICHTIG: Firebase Rules können bis zu 2 Minuten brauchen!

================================================================================
PROBLEM 2: App verwendet gecachte alte Rules
================================================================================

LÖSUNG - Flutter Web (Browser):
1. Öffne Developer Tools (F12)
2. Rechtsklick auf Reload-Button → "Empty Cache and Hard Reload"
3. Oder: Application → Clear Storage → Clear site data

LÖSUNG - APK (Android):
1. Einstellungen → Apps → Weltenbibliothek
2. Tippe auf "Speicher" → "Cache leeren"
3. Tippe auf "Daten löschen" (⚠️ Löscht lokale Daten!)
4. App neu starten

================================================================================
PROBLEM 3: Firestore Database existiert nicht
================================================================================

Der häufigste Grund für Permission-Denied!

PRÜFEN:
1. Gehe zu: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore
2. Siehst du "Create database" Button?
   → Dann existiert KEINE Datenbank!

LÖSUNG:
1. Klicke auf "Create database"
2. Wähle "Start in test mode" oder "Start in production mode"
3. Wähle Location (z.B. "europe-west3")
4. Klicke auf "Enable"
5. Warte 1-2 Minuten
6. DANN setze die Rules neu

⚠️  KRITISCH: Ohne Datenbank funktionieren Rules nicht!

================================================================================
PROBLEM 4: Rules wurden nicht korrekt übernommen
================================================================================

PRÜFEN:
1. Gehe zu: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules
2. Siehst du deine neuen Rules?
3. Steht oben: "Published" mit Zeitstempel?

LÖSUNG:
1. Kopiere die Rules nochmal (siehe COMPLETE_FIREBASE_RULES.txt)
2. Ersetze ALLES im Editor
3. Klicke auf "Publish"
4. Warte auf grüne Bestätigung "Rules published successfully"

================================================================================
PROBLEM 5: Firebase SDK nicht korrekt initialisiert
================================================================================

PRÜFEN - In der App:
- Öffne Developer Console (Chrome F12)
- Suche nach Firebase-Fehlern
- Typische Fehler:
  * "Firebase: No Firebase App '[DEFAULT]' has been created"
  * "Firebase: Firebase App named '[DEFAULT]' already exists"

LÖSUNG:
Die App muss firebase_options.dart haben!

Prüfe ob Datei existiert:
ls -la lib/firebase_options.dart

Falls nicht vorhanden, erstelle sie mit Firebase Flutterfire CLI.

================================================================================
PROBLEM 6: Indexes fehlen immer noch
================================================================================

Der "Missing Index" Fehler ist NORMAL bei komplexen Queries!

AUTOMATISCHE LÖSUNG:
1. Öffne die App
2. Gehe zu dem Feature mit Fehler (z.B. "Verlorene Zivilisationen")
3. Der Fehler zeigt einen LINK
4. Klicke auf den Link → führt direkt zur Index-Erstellung
5. Klicke auf "Create Index"
6. Warte 2-5 Minuten

MANUELLE LÖSUNG:
1. Gehe zu: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes
2. Klicke auf "Create Index"
3. Konfiguriere:
   Collection: telegram_videos
   Field: topic (Ascending)
   Field: timestamp (Descending)
4. Klicke "Create"
5. Wiederhole für andere Collections

⚠️  Index-Build dauert 2-5 Minuten!

================================================================================
PROBLEM 7: Firebase Authentication nicht aktiviert
================================================================================

Falls du Production Rules verwendest (require auth), muss Auth aktiviert sein!

PRÜFEN:
1. Gehe zu: https://console.firebase.google.com/project/weltenbibliothek-5d21f/authentication
2. Ist "Email/Password" aktiviert?

LÖSUNG:
1. Klicke auf "Get started" (falls noch nicht aktiviert)
2. Gehe zu "Sign-in method"
3. Aktiviere "Email/Password"
4. Speichern

ODER: Verwende Development Rules (allow read, write: if true;)

================================================================================
PROBLEM 8: Falsche Firebase-Konfiguration in der App
================================================================================

Die App muss mit dem richtigen Firebase-Projekt verbunden sein!

PRÜFEN:
1. Öffne: android/app/google-services.json (falls vorhanden)
2. Prüfe: "project_id": "weltenbibliothek-5d21f"
3. Stimmt die Project ID?

ODER:
1. Öffne: lib/firebase_options.dart
2. Prüfe: projectId: 'weltenbibliothek-5d21f'

LÖSUNG:
Falls falsch → Download neue google-services.json aus Firebase Console

================================================================================
🎯 SCHNELLTEST - Prüfe diese 3 Dinge SOFORT:
================================================================================

TEST 1: Firestore Database existiert?
→ https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/data
→ Siehst du Collections? Oder "Create database"?

TEST 2: Rules sind published?
→ https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules
→ Steht oben "Published" mit aktuellem Zeitstempel?

TEST 3: App-Cache geleert?
→ Android: Einstellungen → Apps → Weltenbibliothek → Cache leeren
→ Web: F12 → Application → Clear Storage

================================================================================
💡 EMPFOHLENE REIHENFOLGE:
================================================================================

1. ✅ Prüfe ob Firestore Database existiert (TEST 1)
   ❌ Fehlt? → Erstelle Database JETZT!

2. ✅ Setze Development Rules (einfachste):
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }

3. ✅ Publish Rules und warte 60 Sekunden

4. ✅ Lösche App-Cache komplett

5. ✅ Starte App neu

6. ✅ Teste "Telegram-Archiv" → sollte jetzt funktionieren

7. ⚠️  Indexes fehlen noch? → Klicke auf Auto-Link im Fehler

================================================================================
🆘 NOTFALL-LÖSUNG: Kompletter Reset
================================================================================

Falls NICHTS hilft:

1. Deinstalliere die App komplett
2. Gehe zu Firebase Console
3. Lösche ALLE Firestore Rules
4. Setze diese minimale Rule:
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
5. Warte 2 Minuten
6. Installiere App neu
7. Starte App

================================================================================
📞 WEITERE HILFE BENÖTIGT?
================================================================================

Wenn die Fehler IMMER NOCH da sind, sende mir:

1. Screenshot des aktuellen Fehlers
2. Screenshot von Firebase Rules (Published?)
3. Screenshot von Firestore Database (Existiert?)
4. Welche App-Version? (APK oder Web?)
5. Welcher Fehler genau? (Permission oder Index?)

Dann kann ich gezielter helfen!

================================================================================
""")
