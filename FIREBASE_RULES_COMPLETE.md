# 🔥 Weltenbibliothek - Komplette Firebase Rules

## 📋 Projekt-Informationen

- **Projekt:** weltenbibliothek-5d21f
- **Version:** 2.14.4 (Build 51)
- **Telegram Service:** V4
- **Package:** com.example.app

---

## 🎯 3 Rule-Optionen

### Option 1: Development Rules ⚡ (EMPFOHLEN für Testing)

**Verwende diese für:** Development, Testing, Debugging

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Vorteile:**
- ✅ Keine Permission-Fehler
- ✅ Sofort funktional
- ✅ Einfach zu verstehen

**Nachteile:**
- ❌ Keine Sicherheit (Jeder kann alles)
- ❌ Nicht für Production

---

### Option 2: Production Rules 🔒 (Für Live-Deployment)

**Verwende diese für:** Production, Live-App, echte User

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Telegram Collections - Public Read, Authenticated Write
    match /telegram_videos/{videoId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn();
    }
    
    match /telegram_photos/{photoId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn();
    }
    
    match /telegram_documents/{documentId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn();
    }
    
    match /telegram_audio/{audioId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn();
    }
    
    match /telegram_feed/{postId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn();
    }
    
    match /telegram_messages/{messageId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update: if isSignedIn() && (
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['favorite_by', 'read_by', 'reminder_at', 'reminder_status'])
        || isAdmin()
      );
      allow delete: if isAdmin();
    }
    
    // Live Chat - Authenticated Only
    match /live_chat_messages/{messageId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
                     (isOwner(resource.data.user_id) || isAdmin());
      allow delete: if isAdmin();
    }
    
    match /live_chat_participants/{participantId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
                     (isOwner(resource.data.user_id) || isAdmin());
      allow delete: if isSignedIn() && isOwner(resource.data.user_id);
    }
    
    // User Management
    match /users/{userId} {
      allow read: if true;
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    match /user_settings/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    match /user_favorites/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Configuration
    match /telegram_config/{configId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /app_config/{configId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Schumann Resonance
    match /schumann_resonance/{dataId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if isSignedIn() && 
                   resource.data.user_id == request.auth.uid;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() && 
                             resource.data.user_id == request.auth.uid;
    }
    
    // Default Fallback
    match /{document=**} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
  }
}
```

**Vorteile:**
- ✅ Differenzierte Berechtigungen
- ✅ Role-based Access Control
- ✅ Sicher für Production

**Nachteile:**
- ❌ Komplexer
- ❌ Benötigt Authentication
- ❌ Admin-Role muss gesetzt sein

---

### Option 3: Hybrid Rules ⚖️ (Balance)

**Verwende diese für:** Beta-Testing, Early Access

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Telegram Content - Public Read
    match /telegram_videos/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /telegram_photos/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /telegram_documents/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /telegram_audio/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /telegram_feed/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /telegram_messages/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    // Live Chat - Authenticated Only
    match /live_chat_messages/{document=**} {
      allow read, write: if isSignedIn();
    }
    
    match /live_chat_participants/{document=**} {
      allow read, write: if isSignedIn();
    }
    
    // User Data - Own data only
    match /users/{userId} {
      allow read: if true;
      allow write: if isSignedIn() && request.auth.uid == userId;
    }
    
    match /user_settings/{userId} {
      allow read, write: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Configuration
    match /telegram_config/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /app_config/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    match /schumann_resonance/{document=**} {
      allow read: if true;
      allow write: if isSignedIn();
    }
    
    // Default
    match /{document=**} {
      allow read, write: if isSignedIn();
    }
  }
}
```

**Vorteile:**
- ✅ Balance zwischen Sicherheit & Usability
- ✅ Public Content zugänglich
- ✅ Private Daten geschützt

---

## 📊 Benötigte Firestore Indexes

### Index 1: Telegram Videos nach Topic
```
Collection: telegram_videos
Fields:
  - topic (Ascending)
  - timestamp (Descending)
```

### Index 2: Gepinnte Nachrichten
```
Collection: telegram_messages
Fields:
  - is_pinned (Ascending)
  - pinned_at (Descending)
```

### Index 3: Favoriten-Nachrichten
```
Collection: telegram_messages
Fields:
  - favorite_by (Array)
  - timestamp (Descending)
```

### Index 4: Thread-Nachrichten
```
Collection: telegram_messages
Fields:
  - thread_id (Ascending)
  - timestamp (Ascending)
```

### Index 5: Live Chat Nachrichten
```
Collection: live_chat_messages
Fields:
  - room_id (Ascending)
  - timestamp (Ascending)
```

---

## 🗂️ Collections in der App

### Telegram Content
- `telegram_videos` - Videos nach Thema
- `telegram_photos` - Fotos/Bilder
- `telegram_documents` - PDFs, Dokumente
- `telegram_audio` - Audio, Sprachnachrichten
- `telegram_feed` - Text-Posts
- `telegram_messages` - V4 Messages mit Extended Features

### Live Chat
- `live_chat_messages` - Chat-Nachrichten
- `live_chat_participants` - Teilnehmer

### User Data
- `users` - User-Profile
- `user_settings` - Einstellungen
- `user_favorites` - Favoriten

### Configuration
- `telegram_config` - Telegram Bot Config
- `app_config` - App-Konfiguration

### Other
- `schumann_resonance` - Schumann-Daten
- `notifications` - Push-Benachrichtigungen
- `analytics_events` - Analytics
- `error_logs` - Fehler-Logs

---

## 🚀 Rules setzen - Schritt für Schritt

### 1. Firebase Console öffnen
```
https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules
```

### 2. Rules Tab wählen
Klicke auf den **"Rules"** Tab

### 3. Rules kopieren
Wähle eine der 3 Optionen oben und kopiere den Code

### 4. Rules einfügen
Ersetze den **GESAMTEN** Inhalt im Editor

### 5. Publish
Klicke auf **"Publish"** (oben rechts)

### 6. Warten
Warte **30 Sekunden**

### 7. App neu starten
Schließe die App komplett und starte neu

---

## ✅ Testing Checklist

Nach dem Setzen der Rules teste:

- [ ] Telegram-Archiv → Videos laden
- [ ] Telegram-Archiv → Filter "Verlorene Zivilisationen"
- [ ] Live Chat → Teilnehmer anzeigen
- [ ] Live Chat → Nachricht senden
- [ ] User Profile → Eigenes Profil bearbeiten
- [ ] Favoriten → Nachricht favorisieren
- [ ] Pin Message → Nachricht anpinnen
- [ ] Thread → Reply erstellen

---

## 🎯 Empfehlung

| Phase | Verwende |
|-------|----------|
| **JETZT (Development)** | Option 1 (Development Rules) |
| **SPÄTER (Beta)** | Option 3 (Hybrid Rules) |
| **PRODUCTION (Live)** | Option 2 (Production Rules) |

---

## 🆘 Troubleshooting

### Permission Denied Fehler
1. Prüfe ob Rules publiziert sind
2. Warte 30 Sekunden nach Publish
3. Starte App neu
4. Prüfe Console-Logs

### Missing Index Fehler
1. Klicke auf den Auto-Link im Fehler
2. Oder erstelle manuell in Firebase Console
3. Warte 2-5 Minuten

### Auth not found
1. Prüfe ob Firebase Auth aktiviert ist
2. Prüfe ob User eingeloggt ist
3. Verwende Development Rules für Tests

---

## 📞 Links

- **Firebase Console:** https://console.firebase.google.com/project/weltenbibliothek-5d21f
- **Firestore Rules:** https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules
- **Firestore Indexes:** https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/indexes

---

**🎉 Viel Erfolg mit den Firebase Rules!**
