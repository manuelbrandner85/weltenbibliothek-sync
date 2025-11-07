# 🎨 Telegram V4 UI-Komponenten - Integrations-Guide

## ✅ Erstellte Widgets

### 1. **MessageCardV4** (`lib/widgets/telegram/message_card_v4.dart`)
Erweiterte Nachrichtenkarte mit allen V4-Features.

**Features:**
- ✅ Pin-Badge für gepinnte Nachrichten
- ⭐ Favoriten-Stern (gold wenn aktiv)
- ✏️ Edit-Button mit Dialog
- 🗑️ Delete-Button mit Bestätigung
- 💬 Reply-Button für Threads
- ⏰ Erinnerung-Button mit DatePicker
- 👁️ Lesebestätigung-Counter
- 🎨 Smooth Animations (Scale on Tap)
- 📱 Long-Press für Expansion

**Verwendung:**
```dart
import 'package:weltenbibliothek/widgets/telegram/message_card_v4.dart';

MessageCardV4(
  message: firestoreMessage,
  currentUserId: 'user123',
  onTap: () => print('Nachricht angeklickt'),
  showActions: true, // Optional: Actions anzeigen
)
```

---

### 2. **MediaGalleryV4** (`lib/widgets/telegram/media_gallery_v4.dart`)
Intelligente Medien-Galerie mit Cache-Support und Streaming.

**Features:**
- 🖼️ Grid-Ansicht (2 oder 3 Spalten)
- 💾 Cache-Status-Badge ("Offline")
- ▶️ Streaming-Badge für streambare Medien
- 🎨 Typ-spezifische Icons (Foto/Video/Audio/Dokument)
- 📱 Kompakt-Modus mit "Mehr anzeigen"
- 🔍 Vollbild-Ansicht bei Tap
- 🎬 Video-Player für streambare Videos

**Verwendung:**
```dart
import 'package:weltenbibliothek/widgets/telegram/media_gallery_v4.dart';

// Kompakt (für MessageCard)
MediaGalleryV4(
  mediaFiles: message['media_files'],
  compact: true,
  maxItemsCompact: 4,
)

// Vollansicht
MediaGalleryV4(
  mediaFiles: message['media_files'],
  compact: false,
)
```

---

### 3. **ThreadView** (`lib/widgets/telegram/thread_view.dart`)
Thread/Reply-Ansicht für Konversationen.

**Features:**
- 💬 Hierarchische Reply-Anzeige
- 📊 Thread-Statistiken (Nachrichten/Antworten/Teilnehmer)
- 🎨 Original-Nachricht hervorgehoben
- ➡️ Thread-Timeline mit Linien
- ⚡ Schnellantwort-Input
- 🔄 Live-Updates via Stream

**Verwendung:**
```dart
import 'package:weltenbibliothek/widgets/telegram/thread_view.dart';

// Als eigener Screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ThreadView(
      threadId: 'thread_abc123',
      currentUserId: 'user123',
    ),
  ),
);
```

---

### 4. **PinnedMessagesBar** (`lib/widgets/telegram/pinned_messages_bar.dart`)
Top-Bar für gepinnte Nachrichten.

**Features:**
- 📌 Zeigt neueste gepinnte Nachricht
- 🎨 Blaue Highlight-Farbe
- 👆 Tap zum Öffnen
- 🔄 Live-Updates
- 📱 Automatisch versteckt wenn keine Pins

**Verwendung:**
```dart
import 'package:weltenbibliothek/widgets/telegram/pinned_messages_bar.dart';

// In App Bar oder am Seiten-Anfang
Column(
  children: [
    PinnedMessagesBar(
      onTap: () {
        // Navigate zu gepinnten Nachrichten
      },
    ),
    // Rest des Screens
  ],
)
```

---

### 5. **FavoritesScreen** (`lib/screens/telegram/favorites_screen.dart`)
Separate Ansicht für alle Favoriten.

**Features:**
- ⭐ Liste aller favorisierten Nachrichten
- 🔄 Live-Updates
- 📱 MessageCardV4 Integration
- 🎨 Empty State
- 🔍 Filter-Button (TODO)

**Verwendung:**
```dart
import 'package:weltenbibliothek/screens/telegram/favorites_screen.dart';

// Als Navigation-Ziel
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FavoritesScreen(
      currentUserId: 'user123',
    ),
  ),
);
```

---

## 📦 Integration in bestehende Screens

### **Beispiel: Telegram Feed Screen**

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:weltenbibliothek/services/telegram_service.dart';
import 'package:weltenbibliothek/widgets/telegram/message_card_v4.dart';
import 'package:weltenbibliothek/widgets/telegram/pinned_messages_bar.dart';
import 'package:weltenbibliothek/screens/telegram/favorites_screen.dart';

class TelegramFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final telegramService = Provider.of<TelegramService>(context);
    final currentUserId = 'user123'; // Von deinem Auth-Service
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Telegram Feed'),
        actions: [
          // Favoriten-Button
          IconButton(
            icon: Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    currentUserId: currentUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Gepinnte Nachrichten Bar
          PinnedMessagesBar(
            onTap: () {
              // Optional: Navigate zu allen gepinnten Nachrichten
            },
          ),
          
          // Feed Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('telegram_messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index].data() 
                        as Map<String, dynamic>;
                    
                    return MessageCardV4(
                      message: message,
                      currentUserId: currentUserId,
                      onTap: () {
                        // Optional: Navigate zu Thread-Ansicht
                        if (message['thread_id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThreadView(
                                threadId: message['thread_id'],
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Firestore Query-Beispiele

### **Alle gepinnten Nachrichten**
```dart
FirebaseFirestore.instance
  .collection('telegram_messages')
  .where('is_pinned', isEqualTo: true)
  .orderBy('pinned_at', descending: true)
  .snapshots();
```

### **Favoriten eines Users**
```dart
FirebaseFirestore.instance
  .collection('telegram_messages')
  .where('favorite_by', arrayContains: 'user123')
  .orderBy('timestamp', descending: true)
  .snapshots();
```

### **Thread-Nachrichten**
```dart
FirebaseFirestore.instance
  .collection('telegram_messages')
  .where('thread_id', isEqualTo: 'thread_abc')
  .orderBy('timestamp', descending: false)
  .snapshots();
```

### **Ungelesene Nachrichten**
```dart
FirebaseFirestore.instance
  .collection('telegram_messages')
  .where('read_by', whereNotIn: ['user123'])
  .orderBy('timestamp', descending: true)
  .snapshots();
```

---

## 🔧 Provider Setup

Stelle sicher, dass TelegramService im Provider verfügbar ist:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TelegramService()),
    // ... andere Provider
  ],
  child: MyApp(),
)
```

---

## 🚀 Nächste Schritte

1. **Integration testen**: Widgets in bestehenden Screens einbauen
2. **User ID Management**: Aktuellen User aus AuthService holen
3. **Reminder-Feature fertigstellen**: Backend-Logic für Erinnerungen
4. **Filter-Optionen**: Filter für FavoritesScreen implementieren
5. **Benachrichtigungen**: Push-Notifications bei neuen Replies

---

## 📱 Beispiel-App-Flow

```
Main Screen
  ↓
TelegramFeedScreen
  ├─ PinnedMessagesBar (Top)
  ├─ MessageCardV4 (Liste)
  │   ├─ Tap: ThreadView
  │   ├─ Edit: Dialog
  │   ├─ Reply: Dialog → ThreadView
  │   └─ Favorite: Toggle
  └─ Actions
      ├─ Favoriten-Button → FavoritesScreen
      └─ Refresh
```

---

**Alle Widgets sind einsatzbereit! 🎉**
