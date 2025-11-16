# 🔧 GitHub Setup - Schritt für Schritt

## ⚠️ DU MUSST JETZT GITHUB EINRICHTEN!

Die App ist bereit für GitHub Push, aber GitHub muss erst autorisiert werden.

---

## 📋 ANLEITUNG

### Schritt 1: Gehe zum #github Tab
1. Öffne deine Code Sandbox
2. Klicke auf den **#github Tab** (oben in der Interface)
3. Du siehst die GitHub-Konfiguration

### Schritt 2: Autorisiere GitHub
1. Klicke auf **"Authorize GitHub App"** (falls noch nicht autorisiert)
2. Melde dich bei GitHub an (falls erforderlich)
3. Erlaube der App Zugriff auf deine Repositories

### Schritt 3: Repository auswählen/erstellen

**Option A: Bestehendes Repository verwenden**
- Wähle ein Repository aus der Liste
- Klicke "Connect"

**Option B: Neues Repository erstellen**
- Klicke "Create New Repository"
- Name: `weltenbibliothek` (oder eigener Name)
- Beschreibung: "Weltenbibliothek - Chat, Livestreaming, KI, Karte"
- Visibility: Public oder Private (deine Wahl)
- Klicke "Create"

### Schritt 4: Bestätigung
Du solltest jetzt sehen:
✅ "GitHub connected"
✅ Repository-Name angezeigt
✅ Bereit für Push

---

## 🚀 DANACH: AUTOMATISCHER PUSH

**Sobald GitHub eingerichtet ist, sage mir Bescheid!**

Dann führe ich automatisch aus:
```bash
git push origin main
```

Und GitHub Actions wird:
1. ✅ Code erhalten
2. ✅ Android APK bauen (5-10 Minuten)
3. ✅ APK als Artifact bereitstellen
4. ✅ Release mit Download-Link erstellen

---

## 📱 APK HERUNTERLADEN (nach Build)

### Wo findest du die APK?

1. **Via GitHub Actions:**
   - Gehe zu: `https://github.com/DEIN-USERNAME/DEIN-REPO/actions`
   - Klicke auf den neuesten Workflow "Build Android APK"
   - Scrolle zu "Artifacts"
   - Download `weltenbibliothek-debug.apk`

2. **Via Releases:**
   - Gehe zu: `https://github.com/DEIN-USERNAME/DEIN-REPO/releases`
   - Neueste Release öffnen
   - Download `app-debug.apk` unter "Assets"

---

## 🎯 WAS PASSIERT BEIM PUSH?

### Workflow:
```
1. git push origin main
   ↓
2. GitHub Actions startet
   ↓
3. Node.js 20 installiert
   ↓
4. npm install
   ↓
5. npm run build
   ↓
6. Java JDK 17 Setup
   ↓
7. Android SDK Setup
   ↓
8. npx cap sync android
   ↓
9. ./gradlew assembleDebug
   ↓
10. APK Upload als Artifact
    ↓
11. Release erstellt (mit Download)
```

**Dauer:** ~5-10 Minuten

---

## 📦 WAS IST IN DER APK?

### App-Details:
- **Name:** Weltenbibliothek
- **Package:** com.weltenbibliothek.app
- **Version:** 1.0.0
- **Größe:** ~50-70 MB
- **Backend:** https://efbbace7.weltenbibliothek.pages.dev

### Features:
✅ Login/Register  
✅ Chat (💬 Allgemein + 🎵 Musik + eigene Gruppen)  
✅ Livestreaming mit Agora RTC  
✅ KI-Chat mit Google Gemini  
✅ Weltkarte mit Events  
✅ Cost Protection System  
✅ Offline-Modus  
✅ Bottom Navigation  

---

## 🔧 NACH DEM PUSH

### Wichtig: Database Migrationen!

Nach dem ersten Push musst du:

```bash
# 1. D1 Migrationen anwenden
npx wrangler d1 migrations apply weltenbibliothek-production

# 2. Default Chats erstellen
npx wrangler d1 execute weltenbibliothek-production --file=./create_default_chats.sql

# 3. Verifizieren
npx wrangler d1 execute weltenbibliothek-production --command="SELECT * FROM chats"
```

**Ohne diese Schritte funktioniert die App nicht richtig!**

---

## 📱 APK AUF HANDY INSTALLIEREN

### Android Installation:

1. **APK herunterladen** (siehe oben)
2. **Auf Handy übertragen:**
   - Via USB
   - Via Email
   - Via Cloud (Google Drive, etc.)
   - Direkt auf Handy downloaden

3. **Installation erlauben:**
   - Einstellungen → Sicherheit
   - "Unbekannte Quellen" aktivieren
   - Oder: "Diese Quelle erlauben" (Android 8+)

4. **APK installieren:**
   - APK-Datei öffnen
   - "Installieren" klicken
   - Warten...
   - "Fertig" → "Öffnen"

5. **App nutzen:**
   - Registrieren oder Login
   - Chat öffnen
   - Features testen!

---

## 🔄 UPDATES

### Neue APK bei jeder Änderung:

```bash
# Code ändern
git add .
git commit -m "Neue Features"
git push origin main

# Warte 10 Minuten
# Neue APK downloaden
# Auf Handy installieren (überschreibt alte Version)
```

---

## 🐛 TROUBLESHOOTING

### "GitHub Authorization failed"
**Lösung:**
1. Gehe zu https://github.com/settings/apps
2. Prüfe, ob die Sandbox-App autorisiert ist
3. Falls nicht: Erneut autorisieren im #github Tab

### "Repository not found"
**Lösung:**
1. Prüfe Repository-Name
2. Stelle sicher, dass du Zugriff hast
3. Bei Private Repos: App muss Zugriff haben

### "Push rejected"
**Lösung:**
```bash
# Pull erst, dann push
git pull origin main --rebase
git push origin main
```

### "APK Build failed"
**Lösung:**
1. Schaue in GitHub Actions Logs
2. Häufige Fehler:
   - Gradle timeout (einfach nochmal pushen)
   - Dependencies fehlen (sollte nicht passieren)
3. Workflow nochmal starten: Actions → Re-run jobs

---

## 🎊 BEREIT FÜR PUSH!

**Sobald du GitHub eingerichtet hast:**
- Sage mir Bescheid
- Ich pushe den Code
- GitHub Actions baut die APK
- Du kannst sie in 10 Minuten downloaden!

---

**Status:** ⏳ Warte auf GitHub-Setup  
**Next:** GitHub autorisieren → Push → APK Download  
**ETA:** 10-15 Minuten nach GitHub-Setup
