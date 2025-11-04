# ⚡ Weltenbibliothek - Quick Deploy Guide

## 🚀 5-Minuten Deployment

### SCHRITT 1: Firebase Security Rules setzen

1. Gehe zu **Firebase Console**: https://console.firebase.google.com/
2. Wähle Projekt: **weltenbibliothek-5d21f**
3. **Firestore Database** → **Rules**
4. **Kopiere KOMPLETTEN Inhalt** von `firestore_production.rules`
5. **Ersetze** alle Rules im Editor
6. Klicke **"Publish"**

---

### SCHRITT 2: Cloud Functions deployen (Optional aber empfohlen)

```bash
# Im Terminal
cd /home/user/flutter_app/cloud_functions

# Dependencies installieren
npm install

# Login (wenn nötig)
firebase login

# Deploy Functions
firebase deploy --only functions
```

**Was die Functions machen:**
- ✅ Push Notifications bei neuen Chat-Nachrichten
- ✅ Automatisches Cleanup alter Messages
- ✅ User Presence Updates

---

### SCHRITT 3: Android APK bauen

```bash
cd /home/user/flutter_app

# Clean build
flutter clean
flutter pub get

# Build Release APK
flutter build apk --release
```

**APK Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

**Dateigröße:** ~50-70 MB

---

### SCHRITT 4: APK herunterladen

Die APK befindet sich hier:
```
/home/user/flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

**Download-Methoden:**
1. Via Browser (wenn Sandbox File-System zugänglich)
2. Via `scp` wenn SSH verfügbar
3. Via Cloud Storage Upload

---

## 🎯 SCHNELLTEST VOR DEPLOYMENT

### 1. Web-Version testen

```bash
cd /home/user/flutter_app

# Build web
flutter build web --release

# Serve locally
python3 -m http.server 5060 --directory build/web
```

**Öffne:** `http://localhost:5060`

### 2. Test-Checklist

- [ ] Login funktioniert
- [ ] Chat laden funktioniert
- [ ] Nachrichten senden funktioniert
- [ ] Bilder hochladen funktioniert (falls Firebase Storage konfiguriert)
- [ ] Reactions funktionieren
- [ ] Gruppen erstellen funktioniert

---

## 🔥 WICHTIGE FIREBASE KONFIGURATION

### Firestore Database

**Status prüfen:**
1. Firebase Console → Firestore Database
2. Sollte **aktiviert** sein
3. Sollte **Daten enthalten** (Users, Chat-Rooms)

### Authentication

**Email/Password aktivieren:**
1. Firebase Console → Authentication
2. Sign-in method → Email/Password
3. **Enable** aktivieren

### Storage

**Für Bilder-Upload:**
1. Firebase Console → Storage
2. **Get Started** klicken
3. Default Rules akzeptieren (später via `firebase.storage.rules` anpassen)

---

## 📱 APK INSTALLATION

### Auf Android-Gerät:

1. **Enable Unknown Sources:**
   - Settings → Security → Unknown Sources → Enable

2. **Transfer APK:**
   - Via USB
   - Via Email
   - Via Cloud Storage

3. **Install:**
   - Tap APK file
   - Follow installation prompts

---

## 🐛 HÄUFIGE PROBLEME

### Problem: "App not installed"
**Lösung:** Alte Version deinstallieren, dann neu installieren

### Problem: "Permission Denied" in Firestore
**Lösung:** Firebase Rules deployed? Siehe SCHRITT 1

### Problem: "No Firebase App"
**Lösung:** google-services.json im richtigen Pfad? (`android/app/`)

### Problem: Bilder laden nicht
**Lösung:** Firebase Storage aktiviert?

### Problem: Notifications funktionieren nicht
**Lösung:** Cloud Functions deployed? Siehe SCHRITT 2

---

## ✅ DEPLOYMENT ERFOLGREICH WENN:

- ✅ APK installiert sich ohne Fehler
- ✅ Login/Registration funktioniert
- ✅ Chats laden
- ✅ Nachrichten senden funktioniert
- ✅ User Profile öffnen funktioniert
- ✅ Keine Firestore Permission Errors

---

## 🎉 PRODUCTION READY CHECKLIST

### Vor Play Store Upload:

- [ ] App Icon gesetzt (nicht Default Flutter Icon)
- [ ] Package Name angepasst (nicht `com.example.app`)
- [ ] Version Code erhöht
- [ ] Signing Key erstellt
- [ ] ProGuard Rules konfiguriert
- [ ] Privacy Policy URL hinzugefügt
- [ ] Permissions dokumentiert

### App Signing (für Play Store):

```bash
# Keystore erstellen
keytool -genkey -v -keystore weltenbibliothek-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias weltenbibliothek

# In android/key.properties:
storePassword=<password>
keyPassword=<password>
keyAlias=weltenbibliothek
storeFile=<path-to-keystore>
```

---

## 📊 NACH DEPLOYMENT

### Monitoring

**Firebase Console checken:**
- Authentication → User Count
- Firestore → Reads/Writes
- Storage → Usage
- Functions → Invocations

### Logs

```bash
# Function Logs
firebase functions:log

# Android Logs (wenn Gerät verbunden)
adb logcat -s flutter
```

---

## 🔄 UPDATES DEPLOYEN

### Code-Update:

```bash
cd /home/user/flutter_app

# Version erhöhen in pubspec.yaml
# version: 1.1.0+6

# Build neue APK
flutter build apk --release
```

### Rules-Update:

```bash
firebase deploy --only firestore:rules
```

### Functions-Update:

```bash
cd cloud_functions
firebase deploy --only functions
```

---

## 💡 TIPPS

1. **Teste IMMER in Debug-Mode vor Release**
2. **Backup deine Firestore-Daten regelmäßig**
3. **Monitor die Firebase Usage** (könnte Kosten verursachen)
4. **Setze Budget Alerts** in Firebase Console
5. **Versioniere deine APKs** (behalte alte Versionen)

---

**Geschätzte Deploy-Zeit:** 5-15 Minuten  
**Schwierigkeit:** ⭐⭐ (Mittel)

🎉 **Viel Erfolg!**
