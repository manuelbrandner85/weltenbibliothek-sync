# 📱 Android APK Build Anleitung

## 🎯 Übersicht

Es gibt **3 Methoden** um die Weltenbibliothek APK zu bauen:

1. ✅ **GitHub Actions** (Automatisch, empfohlen)
2. 🔧 **Lokaler Build mit Android Studio**
3. 💻 **Command Line Build** (fortgeschrittene Nutzer)

---

## 🚀 Methode 1: GitHub Actions (EMPFOHLEN)

### Vorteile:
- ✅ Vollautomatisch
- ✅ Keine lokale Installation nötig
- ✅ APK direkt zum Download
- ✅ Für jeden Git-Push automatisch

### Schritte:

1. **Code zu GitHub pushen:**
   ```bash
   # GitHub Environment einrichten (einmalig)
   # Rufe setup_github_environment auf
   
   # Zu GitHub pushen
   git push origin main
   ```

2. **GitHub Actions ausführen:**
   - Gehe zu: https://github.com/DEIN-USERNAME/DEIN-REPO/actions
   - Der Workflow "Build Android APK" wird automatisch gestartet
   - Warte ca. 5-10 Minuten

3. **APK herunterladen:**
   - Klicke auf den abgeschlossenen Workflow
   - Unter "Artifacts" findest du `weltenbibliothek-debug.apk`
   - Download die APK
   - Oder: Schaue unter "Releases" für automatisch erstellte Releases

4. **APK auf Android installieren:**
   - Übertrage APK auf dein Handy (USB, Email, Cloud)
   - Aktiviere "Unbekannte Quellen" in Android-Einstellungen
   - Öffne die APK-Datei
   - Klicke "Installieren"
   - Fertig! 🎉

---

## 🔧 Methode 2: Lokaler Build mit Android Studio

### Voraussetzungen:
- Android Studio installiert
- Java JDK 17 installiert
- Android SDK installiert

### Schritte:

1. **Projekt vorbereiten:**
   ```bash
   cd /pfad/zur/weltenbibliothek
   npm install
   npm run build
   npx cap sync android
   ```

2. **Android Studio öffnen:**
   - Öffne Android Studio
   - File → Open → Wähle `android/` Ordner
   - Warte bis Gradle Sync abgeschlossen ist

3. **APK bauen:**
   - Build → Build Bundle(s) / APK(s) → Build APK(s)
   - Warte bis Build abgeschlossen ist
   - Klicke auf "locate" in der Benachrichtigung
   - APK befindet sich in: `android/app/build/outputs/apk/debug/app-debug.apk`

4. **APK installieren:**
   - Siehe Methode 1, Schritt 4

---

## 💻 Methode 3: Command Line Build

### Voraussetzungen:
- Android SDK installiert
- Java JDK 17 installiert
- ANDROID_HOME Umgebungsvariable gesetzt

### Schritte:

1. **Umgebung vorbereiten:**
   ```bash
   export ANDROID_HOME=/pfad/zu/android-sdk
   export JAVA_HOME=/pfad/zu/jdk-17
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
   ```

2. **Projekt bauen:**
   ```bash
   cd /pfad/zur/weltenbibliothek
   npm install
   npm run build
   npx cap sync android
   cd android
   ./gradlew assembleDebug
   ```

3. **APK finden:**
   ```bash
   # APK befindet sich in:
   android/app/build/outputs/apk/debug/app-debug.apk
   ```

4. **APK installieren:**
   ```bash
   # Via ADB (Android Debug Bridge)
   adb install app-debug.apk
   
   # Oder manuell: Siehe Methode 1, Schritt 4
   ```

---

## 📦 APK-Dateien Übersicht

### Debug APK (für Entwicklung/Testing):
- **Dateiname**: `app-debug.apk`
- **Größe**: ~50-70 MB
- **Signatur**: Debug-Signatur (nur für Testing)
- **Installation**: Erfordert "Unbekannte Quellen"

### Release APK (für Produktion):
- **Dateiname**: `app-release.apk`
- **Größe**: ~40-60 MB (optimiert)
- **Signatur**: Release-Signatur (für Play Store)
- **Installation**: Kann im Play Store veröffentlicht werden

---

## 🔐 APK signieren (für Play Store)

Wenn du die App im Play Store veröffentlichen möchtest:

1. **Keystore erstellen:**
   ```bash
   keytool -genkey -v -keystore weltenbibliothek.keystore \
     -alias weltenbibliothek -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **build.gradle anpassen:**
   ```gradle
   android {
       signingConfigs {
           release {
               storeFile file("weltenbibliothek.keystore")
               storePassword "DEIN_PASSWORD"
               keyAlias "weltenbibliothek"
               keyPassword "DEIN_PASSWORD"
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

3. **Release APK bauen:**
   ```bash
   ./gradlew assembleRelease
   ```

---

## ⚙️ Capacitor Konfiguration anpassen

### Server URL ändern (nach Cloudflare Deployment):

Bearbeite `capacitor.config.ts`:

```typescript
const config: CapacitorConfig = {
  appId: 'com.weltenbibliothek.app',
  appName: 'Weltenbibliothek',
  webDir: 'dist',
  
  server: {
    // Setze deine Cloudflare Pages URL
    url: 'https://weltenbibliothek.pages.dev',
    cleartext: true
  }
};
```

Dann:
```bash
npx cap sync android
# APK neu bauen
```

---

## 🐛 Troubleshooting

### Problem: "SDK not found"
**Lösung:**
```bash
export ANDROID_HOME=/pfad/zu/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

### Problem: "Java version mismatch"
**Lösung:**
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
java -version  # Sollte Java 17 anzeigen
```

### Problem: "Build failed with exception"
**Lösung:**
```bash
cd android
./gradlew clean
./gradlew assembleDebug --stacktrace
```

### Problem: "APK installiert nicht"
**Lösung:**
- Aktiviere "Unbekannte Quellen" in Android-Einstellungen
- Stelle sicher, dass die APK vollständig heruntergeladen wurde
- Prüfe, ob genug Speicherplatz vorhanden ist

---

## 📱 App-Icons und Splash Screen anpassen

### Icons ändern:

1. Ersetze Dateien in:
   ```
   android/app/src/main/res/mipmap-*/ic_launcher.png
   ```

2. Oder verwende Android Studio:
   - File → New → Image Asset
   - Wähle Icon Type: Launcher Icons
   - Lade dein Icon hoch
   - Generate

### Splash Screen ändern:

1. Ersetze Dateien in:
   ```
   android/app/src/main/res/drawable-*/splash.png
   ```

2. Oder bearbeite `capacitor.config.ts`:
   ```typescript
   plugins: {
     SplashScreen: {
       launchShowDuration: 2000,
       backgroundColor: '#0f172a',
       androidScaleType: 'CENTER_CROP'
     }
   }
   ```

---

## 🎯 Nächste Schritte

Nach erfolgreichem Build:

1. ✅ Teste die APK auf deinem Handy
2. ✅ Prüfe alle Features (Chat, Livestream, KI, Karte)
3. ✅ Teste offline-Funktionalität
4. ✅ Bei Problemen: Schaue in Android Logcat (Android Studio)
5. ✅ Feedback geben und weitere Features entwickeln!

---

## 📚 Weitere Ressourcen

- [Capacitor Dokumentation](https://capacitorjs.com/docs)
- [Android Developer Guide](https://developer.android.com)
- [Gradle Build Tool](https://gradle.org/guides/)

---

**Erstellt für Weltenbibliothek**  
Version: 1.0.0  
Datum: 2025-11-16
