# 🚀 Weltenbibliothek - Deployment Guide

## 📋 Pre-Deployment Checklist

### ✅ Firebase Setup
- [ ] Firebase Projekt erstellt
- [ ] Firestore Database aktiviert
- [ ] Firebase Authentication aktiviert (Email/Password)
- [ ] Firebase Storage aktiviert
- [ ] Firebase Cloud Messaging (FCM) aktiviert
- [ ] google-services.json heruntergeladen und in `android/app/` platziert
- [ ] firebase-admin-sdk.json heruntergeladen (für Cloud Functions)

### ✅ Android Setup
- [ ] Package Name konfiguriert in `android/app/build.gradle.kts`
- [ ] AndroidManifest.xml Package Name aktualisiert
- [ ] MainActivity.kt im richtigen Package-Pfad
- [ ] App Icon generiert und platziert

### ✅ Firestore Configuration
- [ ] Security Rules deployed (siehe `firestore_production.rules`)
- [ ] Composite Indexes erstellt (siehe unten)
- [ ] Storage Rules konfiguriert

### ✅ Cloud Functions Setup
- [ ] Node.js 18 installiert
- [ ] Firebase CLI installiert: `npm install -g firebase-tools`
- [ ] Firebase login: `firebase login`
- [ ] Functions deployed: `firebase deploy --only functions`

---

## 🔥 Firebase Security Rules Deployment

### 1. Firestore Rules

```bash
# Von der Firebase Console
firebase deploy --only firestore:rules

# Oder manuell in Firebase Console:
# 1. Gehe zu Firestore Database → Rules
# 2. Kopiere Inhalt von firestore_production.rules
# 3. Klicke "Publish"
```

**Rules Datei:** `firestore_production.rules`

### 2. Storage Rules

```bash
# Erstelle firebase.storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Chat Images - nur für authentifizierte User
    match /chat_images/{chatRoomId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User Avatars
    match /user_avatars/{userId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 🔐 Firestore Composite Indexes

### Erforderliche Indexes:

**Wichtig:** Diese Indexes müssen **NICHT** manuell erstellt werden, da wir die Queries so umgeschrieben haben, dass sie ohne Composite Indexes funktionieren!

Sollten dennoch Fehler auftreten, hier die Indexes:

1. **Chat Rooms - Private Chats**
   - Collection: `chat_rooms`
   - Fields: `type` (Ascending), `participants` (Array-contains), `lastActivity` (Descending)

2. **Chat Rooms - Group Chats**
   - Collection: `chat_rooms`
   - Fields: `type` (Ascending), `participants` (Array-contains), `lastActivity` (Descending)

**Auto-Create via Error-Link:**
Wenn ein Index fehlt, zeigt Firebase eine Fehlermeldung mit einem Link. Klicke auf den Link → Firebase erstellt den Index automatisch.

---

## ☁️ Cloud Functions Deployment

### 1. Setup

```bash
cd /home/user/flutter_app/cloud_functions

# Install dependencies
npm install

# Test locally (optional)
firebase emulators:start --only functions
```

### 2. Deploy

```bash
# Deploy alle Functions
firebase deploy --only functions

# Deploy einzelne Function
firebase deploy --only functions:sendChatNotification
```

### 3. Environment Variables (falls benötigt)

```bash
firebase functions:config:set someservice.key="THE API KEY"
```

---

## 📦 Android APK Build

### 1. Vorbereitung

```bash
cd /home/user/flutter_app

# Clean build
flutter clean
flutter pub get

# Check for issues
flutter doctor
flutter analyze
```

### 2. Build APK (Debug)

```bash
flutter build apk --debug
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

### 3. Build APK (Release)

```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 4. Build App Bundle (für Play Store)

```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## 🌐 Web Deployment

### Option A: Firebase Hosting

```bash
# Build web version
flutter build web --release

# Initialize Firebase Hosting (einmalig)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### Option B: Eigener Server

```bash
# Build web version
flutter build web --release

# Upload build/web/ folder to your server
scp -r build/web/* user@server:/var/www/weltenbibliothek/
```

---

## 🔔 Push Notifications Setup

### Android

**Bereits konfiguriert in:**
- `android/app/google-services.json`
- `pubspec.yaml` → `firebase_messaging: 15.1.3`
- `lib/services/fcm_service.dart`

**Testen:**
1. App starten
2. Notification Permission wird automatisch angefragt
3. FCM Token wird in Firestore gespeichert
4. Cloud Functions senden Notifications bei neuen Messages

### iOS (falls später benötigt)

1. APNs Certificate in Firebase Console hochladen
2. `ios/Runner/GoogleService-Info.plist` hinzufügen
3. Push Notification Capability in Xcode aktivieren

---

## 🗂️ Firestore Initial Data

### Chat Rooms erstellen

Die App erstellt automatisch 5 Standard-Community-Chats beim ersten Start:
- 🌍 Allgemeiner Chat
- 👽 UFO-Sichtungen
- 🌊 Erdveränderungen
- ⚡ Schumann-Resonanz
- 🔮 Esoterisches Wissen

**Manuell erstellen (optional):**

```javascript
// In Firebase Console → Firestore → chat_rooms
{
  name: "Test Chat",
  description: "Test Beschreibung",
  type: "community",
  participants: [],
  createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  lastActivity: firebase.firestore.FieldValue.serverTimestamp(),
  avatarUrl: ""
}
```

---

## 🧪 Testing

### 1. Local Testing

```bash
# Run on web
flutter run -d chrome

# Run on Android emulator
flutter run -d <device-id>
```

### 2. Test Checklist

- [ ] Login/Logout funktioniert
- [ ] Community Chats werden geladen
- [ ] Nachrichten senden funktioniert
- [ ] Bilder hochladen funktioniert
- [ ] Reactions funktionieren
- [ ] Private Chats erstellen funktioniert
- [ ] Gruppen erstellen funktioniert
- [ ] User Profile anzeigen funktioniert
- [ ] Notifications erscheinen
- [ ] Online-Status wird aktualisiert

---

## 🐛 Troubleshooting

### Issue: "No Firebase App"
**Lösung:** Prüfe ob `google-services.json` im richtigen Pfad liegt (`android/app/`)

### Issue: "Permission Denied" in Firestore
**Lösung:** Deploye die Security Rules: `firebase deploy --only firestore:rules`

### Issue: "Missing Composite Index"
**Lösung:** Klicke auf den Error-Link oder siehe "Firestore Composite Indexes" oben

### Issue: "FCM Token null"
**Lösung:** 
1. Prüfe ob FCM in Firebase Console aktiviert ist
2. Prüfe Notification Permissions in Android Settings
3. Neustart der App

### Issue: Build Fehler
**Lösung:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📊 Performance Optimization

### 1. Firestore

- Pagination für große Listen implementieren
- Queries limitieren (`.limit(100)`)
- Offline Persistence nutzen

### 2. Images

- Bilder komprimieren vor Upload
- Thumbnails generieren (Cloud Function)
- Caching nutzen (`cached_network_image`)

### 3. App Size

- Remove unused assets
- Enable code shrinking in `build.gradle`
- Use ProGuard rules

---

## 🔒 Security Best Practices

1. **Nie API Keys im Code committen**
2. **Environment Variables nutzen**
3. **Security Rules restriktiv halten**
4. **User Input validieren**
5. **Sensitive Daten verschlüsseln**
6. **Rate Limiting für API Calls**

---

## 📈 Monitoring

### Firebase Console

- **Authentication:** User-Aktivität
- **Firestore:** Database Usage
- **Storage:** Storage Usage
- **Functions:** Execution Logs
- **Crashlytics:** Crash Reports

### Logs

```bash
# Function Logs
firebase functions:log

# Android Logs
adb logcat | grep Flutter
```

---

## 🚀 Go Live Checklist

- [ ] Alle Features getestet
- [ ] Security Rules deployed
- [ ] Cloud Functions deployed
- [ ] APK/AAB gebaut
- [ ] App Icon gesetzt
- [ ] App Name finalisiert
- [ ] Privacy Policy erstellt
- [ ] Terms of Service erstellt
- [ ] Play Store Listing vorbereitet
- [ ] Screenshots erstellt
- [ ] Beta Testing durchgeführt

---

## 📞 Support

**Bei Problemen:**
1. Check Firebase Console Logs
2. Check Flutter Console Output
3. Check `flutter doctor`
4. Google the error message
5. Firebase Support kontaktieren

---

**Version:** 1.0.0  
**Letzte Aktualisierung:** 2024

🎉 **Viel Erfolg mit dem Deployment!**
