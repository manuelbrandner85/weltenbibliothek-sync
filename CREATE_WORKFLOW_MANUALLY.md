# 🔧 GitHub Actions Workflow manuell erstellen

## ⚠️ WICHTIG: Workflow kann nicht automatisch gepusht werden

Die GitHub App hat keine Berechtigung, Workflows zu erstellen. Du musst ihn **manuell über die GitHub Web-UI** erstellen.

---

## 📋 ANLEITUNG (5 Minuten)

### Schritt 1: Gehe zu deinem Repository
🔗 https://github.com/manuelbrandner85/weltenbibliothek-sync

### Schritt 2: Erstelle Workflow-Datei
1. Klicke auf **"Actions"** Tab (oben)
2. Klicke **"set up a workflow yourself"** oder **"New workflow"**
3. Klicke **"Skip this and set up a workflow yourself"**

### Schritt 3: Workflow-Code einfügen
1. Dateiname: `.github/workflows/android-build.yml`
2. Kopiere folgenden Code:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build web app
      run: npm run build
      
    - name: Setup Java JDK
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
        
    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
      
    - name: Sync Capacitor
      run: npx cap sync android
      
    - name: Grant execute permission for gradlew
      run: chmod +x android/gradlew
      
    - name: Build Debug APK
      run: cd android && ./gradlew assembleDebug
      
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: weltenbibliothek-debug.apk
        path: android/app/build/outputs/apk/debug/app-debug.apk
        
    - name: Create Release
      if: github.ref == 'refs/heads/main'
      uses: softprops/action-gh-release@v1
      with:
        tag_name: v1.0.${{ github.run_number }}
        name: Release v1.0.${{ github.run_number }}
        files: android/app/build/outputs/apk/debug/app-debug.apk
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Schritt 4: Commit & Run
1. Klicke **"Commit changes"** (oben rechts)
2. Commit message: "🤖 Add Android APK Build Workflow"
3. Klicke **"Commit changes"** im Dialog
4. Der Workflow startet **automatisch**!

---

## 🚀 NACH DEM ERSTELLEN

### Workflow wird automatisch gestartet!

**Status prüfen:**
1. Gehe zu: https://github.com/manuelbrandner85/weltenbibliothek-sync/actions
2. Du siehst: "Build Android APK" läuft
3. Warte 5-10 Minuten

**APK downloaden:**
1. Workflow abgeschlossen (grüner Haken ✓)
2. Klicke auf den Workflow
3. Scrolle zu **"Artifacts"**
4. Download: **weltenbibliothek-debug.apk**

**Oder via Releases:**
1. Gehe zu: https://github.com/manuelbrandner85/weltenbibliothek-sync/releases
2. Neueste Release öffnen
3. Download **app-debug.apk** unter "Assets"

---

## 📱 APK INSTALLIEREN

### Auf dein Android-Handy:
1. APK auf Handy übertragen
2. Einstellungen → Sicherheit → "Unbekannte Quellen" aktivieren
3. APK öffnen → Installieren
4. App starten
5. Registrieren / Login
6. Fertig! 🎉

---

## 🔄 ZUKÜNFTIGE UPDATES

### Bei jedem Code-Update:

```bash
# Im Sandbox
git add .
git commit -m "Neue Features"
git push origin main

# GitHub Actions baut automatisch neue APK
# Download nach 10 Minuten von GitHub
```

---

## ⚙️ WAS DER WORKFLOW MACHT

```
1. Checkout Code von GitHub
2. Node.js 20 installieren
3. npm install (Dependencies)
4. npm run build (Web App bauen)
5. Java JDK 17 Setup
6. Android SDK installieren
7. Capacitor sync (Web → Android)
8. Gradle Build (APK erstellen)
9. APK Upload als Artifact
10. Release erstellen mit APK
```

**Dauer:** 5-10 Minuten  
**Output:** Fertige APK zum Download

---

## 🎯 NÄCHSTE SCHRITTE

### JETZT SOFORT:
1. ✅ **Workflow manuell erstellen** (siehe oben)
2. ⏳ **10 Minuten warten**
3. ✅ **APK downloaden**
4. ✅ **Auf Handy installieren**

### DANACH (wichtig!):
5. ✅ **D1 Migrationen anwenden:**
   ```bash
   npx wrangler d1 migrations apply weltenbibliothek-production
   ```

6. ✅ **Default Chats erstellen:**
   ```bash
   npx wrangler d1 execute weltenbibliothek-production --file=./create_default_chats.sql
   ```

7. ✅ **App testen!**

---

## 📊 STATUS

- [x] ✅ Code auf GitHub gepusht
- [x] ✅ Cloudflare Deployment live
- [x] ✅ Capacitor konfiguriert
- [ ] ⏳ **Workflow manuell erstellen** ← **DU BIST JETZT DRAN!**
- [ ] ⏳ APK downloaden
- [ ] ⏳ Auf Handy installieren
- [ ] ⏳ D1 Migrationen
- [ ] ⏳ Testen

---

**GitHub Repository:**  
🔗 https://github.com/manuelbrandner85/weltenbibliothek-sync

**Actions Tab:**  
🔗 https://github.com/manuelbrandner85/weltenbibliothek-sync/actions

**Releases:**  
🔗 https://github.com/manuelbrandner85/weltenbibliothek-sync/releases

---

**LOS GEHT'S!** 🚀  
Erstelle jetzt den Workflow und in 10 Minuten hast du deine APK!
