# 🔥 Firebase Integration Guide - Weltenbibliothek

## 📋 Übersicht

Diese Anleitung führt dich Schritt-für-Schritt durch die komplette Firebase-Integration für die Weltenbibliothek-App.

---

## 🎯 Was wird eingerichtet?

- ✅ **Firebase Authentication** - Anonyme Benutzer
- ✅ **Cloud Firestore** - Datenbank für Events & Sichtungen
- ✅ **Firebase Storage** - Medien-Uploads
- ✅ **Firebase Messaging** - Push-Benachrichtigungen
- ✅ **Firebase Analytics** - Nutzungsstatistiken
- ✅ **Security Rules** - Datenschutz & Zugriffskontr

olle

---

## 🚀 SCHRITT 1: Firebase Projekt erstellen

### 1.1 Firebase Console öffnen
1. Gehe zu **https://console.firebase.google.com/**
2. Klicke auf **"Projekt hinzufügen"**
3. Projekt-Name: **`weltenbibliothek`**
4. Google Analytics: **Aktiviert** (empfohlen)
5. Analytics-Standort: **Deutschland** (oder dein Land)
6. Klicke auf **"Projekt erstellen"**

⏱️ **Wartezeit**: ~30 Sekunden

---

## 🔥 SCHRITT 2: Firestore Database erstellen

### 2.1 Firestore initialisieren
1. In Firebase Console → **Build** → **Firestore Database**
2. Klicke auf **"Create database"**
3. **Modus wählen**:
   - **Test Mode**: Für Entwicklung (alle können lesen/schreiben) ⚠️
   - **Production Mode**: Für Produktion (mit Security Rules) ✅
4. **Standort wählen**: `europe-west3 (Frankfurt)` (für beste Performance in Europa)
5. Klicke auf **"Enable"**

⏱️ **Wartezeit**: ~1 Minute

### 2.2 Collections erstellen

Die Collections werden automatisch beim ersten Schreibvorgang erstellt. Struktur:

```
📁 events/              # Historische Ereignisse
  ├── {eventId}/
  │   ├── title: string
  │   ├── description: string
  │   ├── date: timestamp
  │   ├── category: string
  │   ├── perspectives: array
  │   ├── sources: array
  │   ├── trustLevel: number
  │   ├── latitude: number
  │   ├── longitude: number
  │   └── locationName: string

📁 sightings/           # Community-Sichtungen
  ├── {sightingId}/
  │   ├── userId: string
  │   ├── title: string
  │   ├── description: string
  │   ├── type: string
  │   ├── timestamp: timestamp
  │   ├── latitude: number
  │   ├── longitude: number
  │   ├── locationName: string
  │   ├── mediaUrls: array
  │   ├── trustScore: number
  │   ├── verified: boolean
  │   └── reportCount: number

📁 users/               # Benutzer-Profile
  ├── {userId}/
  │   ├── favorites: array
  │   ├── sightingsCount: number
  │   └── updatedAt: timestamp
```

---

## 🔑 SCHRITT 3: Firebase Admin SDK Key erhalten

### 3.1 Service Account erstellen
1. Firebase Console → **Project Settings** (⚙️ Icon)
2. Tab: **Service accounts**
3. **WICHTIG**: Wähle **"Python"** als Admin SDK
4. Klicke auf **"Generate new private key"**
5. Bestätige mit **"Generate key"**
6. JSON-Datei wird heruntergeladen: `weltenbibliothek-firebase-adminsdk-xxxxx.json`

### 3.2 Key hochladen
- Lade die JSON-Datei im **Firebase-Tab** der Sandbox hoch
- Der Key wird gespeichert als: `/opt/flutter/firebase-admin-sdk.json`

---

## 📱 SCHRITT 4: Android App konfigurieren

### 4.1 Android App in Firebase registrieren
1. Firebase Console → **Project Overview**
2. Klicke auf **"Android-App hinzufügen"** (Android-Icon)
3. **Android-Paketname**: `com.weltenbibliothek.weltenbibliothek`
4. **App-Spitzname** (optional): `Weltenbibliothek Android`
5. **SHA-1** (optional, für Auth): Leer lassen für Entwicklung
6. Klicke auf **"App registrieren"**

### 4.2 google-services.json herunterladen
1. Lade die `google-services.json` Datei herunter
2. Upload sie im **Firebase-Tab** der Sandbox
3. Die Datei wird automatisch nach `android/app/google-services.json` kopiert

### 4.3 Gradle-Konfiguration prüfen

Die Gradle-Files sind bereits konfiguriert. Prüfe:

**android/build.gradle.kts**:
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

**android/app/build.gradle.kts**:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

---

## 🌐 SCHRITT 5: Web App konfigurieren

### 5.1 Web App in Firebase registrieren
1. Firebase Console → **Project Overview**
2. Klicke auf **"Web-App hinzufügen"** (</> Icon)
3. **App-Spitzname**: `Weltenbibliothek Web`
4. **Firebase Hosting**: ❌ Nicht aktivieren (verwenden Python Server)
5. Klicke auf **"App registrieren"**

### 5.2 Web-Konfiguration kopieren

Firebase zeigt dir ein Code-Snippet. Kopiere die Werte:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "weltenbibliothek.firebaseapp.com",
  projectId: "weltenbibliothek",
  storageBucket: "weltenbibliothek.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef",
  measurementId: "G-ABCDEF"
};
```

### 5.3 firebase_options.dart aktualisieren

Öffne `lib/firebase_options.dart` und ersetze die Werte:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIza...',                    // ← Dein apiKey
  appId: '1:123456789:web:abcdef',      // ← Dein appId
  messagingSenderId: '123456789',        // ← Dein messagingSenderId
  projectId: 'weltenbibliothek',         // ← Dein projectId
  authDomain: 'weltenbibliothek.firebaseapp.com',
  storageBucket: 'weltenbibliothek.appspot.com',
  measurementId: 'G-ABCDEF',            // ← Dein measurementId
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIza...',                    // ← Android apiKey (aus google-services.json)
  appId: '1:123456789:android:abcdef',  // ← Android appId
  messagingSenderId: '123456789',
  projectId: 'weltenbibliothek',
  storageBucket: 'weltenbibliothek.appspot.com',
);
```

---

## 🔐 SCHRITT 6: Security Rules konfigurieren

### 6.1 Firestore Security Rules

1. Firebase Console → **Firestore Database** → **Rules**
2. Ersetze die Regeln mit:

**Für Entwicklung** (Test Mode):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Alle können lesen
    match /{document=**} {
      allow read: if true;
    }
    
    // Nur authentifizierte Benutzer können schreiben
    match /events/{eventId} {
      allow write: if request.auth != null;
    }
    
    match /sightings/{sightingId} {
      allow write: if request.auth != null;
    }
    
    match /users/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Für Produktion** (Empfohlen):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Events: Alle können lesen, nur Admins schreiben
    match /events/{eventId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Sightings: Authentifiziert lesen/schreiben
    match /sightings/{sightingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && 
                              resource.data.userId == request.auth.uid;
    }
    
    // Users: Nur eigene Daten bearbeiten
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Klicke auf **"Publish"**

### 6.2 Storage Security Rules

1. Firebase Console → **Storage** → **Rules**
2. Ersetze mit:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /sightings/{userId}/{fileName} {
      // Authentifizierte Benutzer können ihre eigenen Bilder hochladen
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // Max 10 MB
                   && request.resource.contentType.matches('image/.*');
      
      // Alle können Bilder lesen
      allow read: if true;
    }
  }
}
```

---

## 🔨 SCHRITT 7: Backend-Daten initialisieren

### 7.1 Python-Skript ausführen

```bash
cd /home/user/flutter_app
python3 scripts/setup_firebase_backend.py
```

**Was das Skript macht**:
1. ✅ Prüft Firebase Admin SDK
2. ✅ Prüft Firestore Database
3. ✅ Erstellt 12 historische Events
4. ✅ Erstellt 10 Beispiel-Sichtungen
5. ✅ Initialisiert Collections

**Output**:
```
🌌 Weltenbibliothek - Firebase Backend Setup
============================================================
✅ firebase-admin importiert
✅ Firebase Admin SDK initialisiert
✅ Firestore Database ist verfügbar

📚 Erstelle historische Events...
✅ 12 historische Events erstellt

👁️ Erstelle Beispiel-Sichtungen...
✅ 10 Sichtungen erstellt

============================================================
✅ Firebase Backend Setup erfolgreich abgeschlossen!

📊 Erstellt:
  - 12 historische Events
  - 10 Community-Sichtungen
  - Collections: events, sightings, users
```

---

## 📲 SCHRITT 8: Flutter App mit Firebase verbinden

### 8.1 main.dart aktualisieren

Die App ist bereits vorbereitet. Prüfe `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### 8.2 Firestore Service verwenden

In deinen Screens:

```dart
import 'package:weltenbibliothek/services/firestore_service.dart';

// Instanz erstellen
final firestoreService = FirestoreService();

// Events laden
final events = await firestoreService.getHistoricalEvents(
  category: EventCategory.alienContact,
  limit: 10,
);

// Event-Stream (Live-Updates)
firestoreService.eventsStream(limit: 20).listen((events) {
  setState(() {
    _events = events;
  });
});

// Sichtung erstellen
final sighting = Sighting(...);
final id = await firestoreService.createSighting(sighting);

// Favoriten speichern
await firestoreService.saveFavorites(userId, ['event1', 'event2']);
```

---

## 🧪 SCHRITT 9: Testen

### 9.1 Web-Test
```bash
cd /home/user/flutter_app
flutter run -d chrome
```

### 9.2 Android-Test
```bash
flutter run -d android
```

### 9.3 Firestore Console prüfen
1. Firebase Console → **Firestore Database**
2. Sieh dir die Collections an:
   - `events` → 12 Dokumente
   - `sightings` → 10 Dokumente
   - `users` → Erstellt bei erster Interaktion

---

## 🔍 Troubleshooting

### Problem: "No Firebase App '[DEFAULT]' has been created"

**Lösung**:
- Prüfe ob `Firebase.initializeApp()` in `main()` aufgerufen wird
- Prüfe ob `firebase_options.dart` existiert
- Prüfe ob die Werte korrekt sind

### Problem: "PERMISSION_DENIED: Missing or insufficient permissions"

**Lösung**:
- Prüfe Security Rules in Firebase Console
- Stelle sicher dass anonyme Auth aktiviert ist:
  - Firebase Console → **Authentication** → **Sign-in method**
  - **Anonymous** → **Enable**

### Problem: "Error: google-services.json not found"

**Lösung**:
- Stelle sicher dass `google-services.json` in `android/app/` liegt
- Datei muss genau so heißen (case-sensitive)
- Führe `flutter clean` aus und build neu

### Problem: Backend-Skript schlägt fehl

**Lösung**:
```bash
# Firebase Admin SDK installieren
pip install firebase-admin==7.1.0

# Admin SDK Key prüfen
ls -la /opt/flutter/firebase-admin-sdk.json

# Firestore Database Status prüfen (Firebase Console)
```

---

## 📊 Nächste Schritte

### 1. Authentication erweitern
```dart
// In lib/services/auth_service.dart erstellen
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Anonyme Anmeldung
  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }
  
  // Email/Password (später)
  Future<User?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }
}
```

### 2. Push-Benachrichtigungen
```dart
// In lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Permission anfragen
    await _messaging.requestPermission();
    
    // Token erhalten
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Nachrichten empfangen
    FirebaseMessaging.onMessage.listen((message) {
      print('Nachricht: ${message.notification?.title}');
    });
  }
}
```

### 3. Analytics tracken
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Event tracken
await analytics.logEvent(
  name: 'view_event',
  parameters: {'event_id': eventId, 'category': 'ufo'},
);

// Screen tracken
await analytics.logScreenView(
  screenName: 'Timeline',
  screenClass: 'TimelineScreen',
);
```

---

## ✅ Checkliste

- [ ] Firebase Projekt erstellt
- [ ] Firestore Database aktiviert
- [ ] Firebase Admin SDK Key hochgeladen
- [ ] Android App registriert
- [ ] google-services.json hochgeladen
- [ ] Web App registriert
- [ ] firebase_options.dart aktualisiert
- [ ] Security Rules konfiguriert
- [ ] Backend-Skript ausgeführt
- [ ] App getestet (Web & Android)
- [ ] Firestore Console geprüft
- [ ] Anonymous Auth aktiviert

---

## 📚 Ressourcen

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Dokumentation](https://firebase.flutter.dev/)
- [Firestore Dokumentation](https://firebase.google.com/docs/firestore)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)

---

**Bei Fragen oder Problemen**: Prüfe die Logs in Firebase Console unter **Firestore → Usage** und **Cloud Functions → Logs**.

🌌 Viel Erfolg mit der Firebase-Integration!
