# 🔥 FIRESTORE KOMPLETT-SETUP - WELTENBIBLIOTHEK

## ⚡ SCHNELLSTE LÖSUNG: 3 EINFACHE SCHRITTE

### SCHRITT 1: DAEMON STARTEN (30 Sekunden)
\`\`\`bash
sudo systemctl start telegram-chat-sync
tail -f /var/log/telegram-chat-sync.log
\`\`\`

### SCHRITT 2: INDEX-URLS KLICKEN (5 Minuten)
Der Daemon zeigt automatisch URLs wie:
\`\`\`
❌ Index required: https://console.firebase.google.com/project/.../firestore/indexes?create_composite=...
\`\`\`

→ Jede URL im Browser öffnen  
→ "Create Index" klicken  
→ Warten bis "Enabled" (5-10 Min pro Index)  
→ 5x wiederholen für alle Indexes

### SCHRITT 3: RULES KOPIEREN (2 Minuten)
Öffnen Sie: https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules

Kopieren Sie diese Rules:

FIRESTORE SECURITY RULES - KOMPLETT FÜR WELTENBIBLIOTHEK
==========================================================

KOPIEREN SIE DEN KOMPLETTEN TEXT UNTEN UND FÜGEN SIE IHN IN DIE FIREBASE CONSOLE EIN:
https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules

───────────────────────────────────────────────────────────────────────────────

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // HILFSFUNKTIONEN (Gemeinsam verwendet)
    // ============================================
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // ============================================
    // BENUTZER-VERWALTUNG (users)
    // ============================================
    match /users/{userId} {
      // Lesen: Authentifizierte Benutzer können alle Profile lesen
      allow read: if isAuthenticated();
      
      // Erstellen: Nur eigenes Profil beim Signup
      allow create: if isAuthenticated() && request.auth.uid == userId;
      
      // Aktualisieren: Nur eigenes Profil oder Admin
      allow update: if isOwner(userId) || isAdmin();
      
      // Löschen: Nur Admin
      allow delete: if isAdmin();
    }
    
    // ============================================
    // BIBLIOTHEKS-EINTRÄGE (library_items)
    // ============================================
    match /library_items/{itemId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Einträge oder Admin
      allow update: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
      
      // Löschen: Eigene Einträge oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // CHAT-NACHRICHTEN (chat_messages)
    // ============================================
    match /chat_messages/{messageId} {
      // Lesen: Alle authentifizierten Benutzer
      // (Öffentlicher Chat @Weltenbibliothekchat)
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer (eigene Nachrichten)
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.source == 'app';
      
      // Aktualisieren: Eigene Nachrichten (für Bearbeitung)
      allow update: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || 
                       resource.data.source == 'telegram');
      
      // Löschen: Eigene Nachrichten oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // KOMMENTARE (comments)
    // ============================================
    match /comments/{commentId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Authentifizierte Benutzer
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Kommentare
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      
      // Löschen: Eigene Kommentare oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // VERANSTALTUNGEN (events)
    // ============================================
    match /events/{eventId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Erstellen: Admin oder Event-Creator
      allow create: if isAuthenticated() && 
                      (isAdmin() || request.resource.data.creatorId == request.auth.uid);
      
      // Aktualisieren: Event-Creator oder Admin
      allow update: if isAuthenticated() && 
                      (resource.data.creatorId == request.auth.uid || isAdmin());
      
      // Löschen: Event-Creator oder Admin
      allow delete: if isAuthenticated() && 
                      (resource.data.creatorId == request.auth.uid || isAdmin());
    }
    
    // ============================================
    // BENACHRICHTIGUNGEN (notifications)
    // ============================================
    match /notifications/{notificationId} {
      // Lesen: Nur eigene Benachrichtigungen
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      // Erstellen: System oder Admin
      allow create: if isAdmin();
      
      // Aktualisieren: Nur read-Status ändern (für "gelesen")
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid &&
                      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      
      // Löschen: Eigene Benachrichtigungen
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
    }
    
    // ============================================
    // BOOKMARKS (bookmarks)
    // ============================================
    match /bookmarks/{bookmarkId} {
      // Lesen: Nur eigene Bookmarks
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      
      // Erstellen: Eigene Bookmarks
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Aktualisieren: Eigene Bookmarks
      allow update: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
      
      // Löschen: Eigene Bookmarks
      allow delete: if isAuthenticated() && 
                      resource.data.userId == request.auth.uid;
    }
    
    // ============================================
    // SYSTEM-EINSTELLUNGEN (settings)
    // ============================================
    match /settings/{settingId} {
      // Lesen: Alle authentifizierten Benutzer
      allow read: if isAuthenticated();
      
      // Schreiben: Nur Admin
      allow write: if isAdmin();
    }
    
    // ============================================
    // FALLBACK-REGEL (Deny All)
    // ============================================
    // Alle anderen Pfade sind standardmäßig blockiert
    match /{document=**} {
      allow read, write: if false;
    }
  }
}

───────────────────────────────────────────────────────────────────────────────

INSTALLATION:
=============

1. Öffnen Sie die Firebase Console:
   https://console.firebase.google.com/project/weltenbibliothek-5d21f/firestore/rules

2. Markieren Sie den KOMPLETTEN Text oben (zwischen den Trennlinien)

3. Kopieren Sie den Text (Strg+C / Cmd+C)

4. Fügen Sie ihn in den Rules-Editor in der Firebase Console ein

5. Klicken Sie auf "Veröffentlichen" (Publish)

6. Fertig! ✅

WICHTIG:
========
- Diese Rules enthalten ALLE Collections der Weltenbibliothek
- Sie ersetzen alle vorherigen Rules komplett
- Die Rules sind produktionsbereit und sicher
- Authentifizierte Benutzer haben Zugriff auf ihre Daten
- Admins haben erweiterte Rechte

COLLECTIONS:
============
✅ users - Benutzerprofile
✅ library_items - Bibliothekseinträge
✅ chat_messages - Telegram-Chat-Nachrichten
✅ comments - Kommentare
✅ events - Veranstaltungen
✅ notifications - Benachrichtigungen
✅ bookmarks - Lesezeichen
✅ settings - System-Einstellungen

---

## ✅ FERTIG!

Alle Firestore Rules und Indexes sind jetzt installiert.

**Verifizierung:**
```bash
# Daemon-Logs prüfen (keine Fehler erwartet)
tail -f /var/log/telegram-chat-sync.log

# Erwartete Ausgabe:
# ✅ MadelineProto verbunden
# 🔄 SYNC CYCLE #X
# 🆕 X neue Telegram-Nachrichten
```

