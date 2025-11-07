# 📱 Telegram Service V4 - Erweiterte Features

## 🎯 Überblick

Telegram Service V4 ist eine umfassende Erweiterung der Telegram-Integration mit erweiterten Chat- und Medien-Features für die Flutter App.

---

## ✨ NEUE FEATURES IN V4

### 1️⃣ **Erweiterte Chat-Features**

#### ✏️ Edit / Undo
- **Nachrichten bearbeiten**: Nutzer können eigene Nachrichten nachträglich ändern
- **Nachrichten löschen**: Soft-Delete mit Tracking in Firestore
- **Bearbeitungshistorie**: Zeitstempel der letzten Bearbeitung wird gespeichert

```dart
// Nachricht bearbeiten
await telegramService.editMessage(chatId, messageId, 'Neuer Text');

// Nachricht löschen
await telegramService.deleteMessage(chatId, messageId);
```

#### 📌 Pin / Fixieren
- **Nachrichten anpinnen**: Admins können wichtige Nachrichten oben fixieren
- **Benachrichtigungen**: Optional Mitglieder über gepinnte Nachrichten informieren
- **Mehrere Pins**: Unterstützung für mehrere gepinnte Nachrichten
- **Loslösen**: Pins können wieder entfernt werden

```dart
// Nachricht anpinnen (mit Benachrichtigung)
await telegramService.pinMessage(chatId, messageId, notify: true);

// Nachricht loslösen
await telegramService.unpinMessage(chatId, messageId);

// Alle gepinnten Nachrichten abrufen
Stream<List<dynamic>> pinnedMessages = telegramService.getPinnedMessages();
```

#### 💬 Thread / Reply / Zitat
- **Thread-Support**: Nachrichten können Threads zugeordnet werden
- **Reply-Funktion**: Antworten auf spezifische Nachrichten
- **Zitatanzeige**: Ursprungsnachricht wird im Reply angezeigt
- **Thread-ID Tracking**: Gruppierung von zusammenhängenden Nachrichten

```dart
// Auf Nachricht antworten
await telegramService.sendMessage(
  chatId, 
  'Antwort-Text',
  replyTo: originalMessageId,
);

// Thread-ID wird automatisch gespeichert
// Zugriff über: message['thread_id']
```

#### ✅ Lesebestätigung
- **Read Tracking**: System erfasst wer Nachrichten gelesen hat
- **User-Liste**: Array mit User-IDs der Leser
- **Echtzeit-Updates**: Stream-basierte Updates bei neuen Lesern
- **Privacy-respektierend**: Optionales Feature, kann deaktiviert werden

```dart
// Nachricht als gelesen markieren
await telegramService.markAsRead(messageId, userId);

// Leser-Liste abrufen
final readBy = message['read_by'] as List<String>;
print('Gelesen von ${readBy.length} Nutzern');
```

#### ⏰ Erinnerungen
- **Zeitbasierte Alerts**: Nutzer können sich an Nachrichten erinnern lassen
- **Flexible Zeitpunkte**: Beliebige Zukunfts-Timestamps
- **Push-Benachrichtigungen**: Integration mit Firebase Cloud Messaging
- **Status-Tracking**: Erfassung ob Erinnerung bereits gesendet wurde

```dart
// Erinnerung setzen
final reminderTime = DateTime.now().add(Duration(hours: 2));
await firestore.collection('messages').doc(messageId).update({
  'reminder': {
    'user_id': userId,
    'remind_at': reminderTime,
    'notified': false,
  }
});

// Backend-Cron-Job prüft regelmäßig und sendet Push-Notifications
```

#### ⭐ Favoriten
- **Nachrichten markieren**: Wichtige Nachrichten als Favoriten speichern
- **Chat-Favoriten**: Ganze Chats für schnellen Zugriff markieren
- **Topic-Favoriten**: Themen-basierte Favoriten
- **User-spezifisch**: Jeder Nutzer hat eigene Favoriten-Liste

```dart
// Nachricht zu Favoriten hinzufügen
await telegramService.toggleFavorite(messageId, userId, true);

// Favoriten abrufen
Stream<List<dynamic>> favorites = telegramService.getFavoriteMessages(userId);

// Favoriten entfernen
await telegramService.toggleFavorite(messageId, userId, false);
```

---

### 2️⃣ **Erweiterte Medien-Features**

#### 🖼️ Automatische Thumbnail-Generierung
- **Bilder**: Automatische Thumbnail-Erstellung beim Upload
- **Videos**: Vorschaubilder aus dem ersten Frame
- **PDFs**: Placeholder-Thumbnails für Dokumente
- **Optimierung**: Größenanpassung und Kompression

```dart
// Thumbnails werden automatisch bei der Medien-Verarbeitung erstellt
// Zugriff über Media-Info:
final thumbnailUrl = mediaInfo['thumbnail_url'];
```

#### 🎵 Audio/Video Streaming
- **Kein kompletter Download**: Streaming direkt aus Telegram
- **Range-Support**: Teilweise Downloads für bessere Performance
- **Streamable Detection**: Automatische Erkennung streamfähiger Formate
- **Lokaler Cache**: Optional lokale Speicherung für Offline-Modus

```dart
// Prüfen ob streambar
final isStreamable = mediaInfo['is_streamable'];

if (isStreamable) {
  // Video-Player mit Stream-URL
  VideoPlayerController.network(mediaInfo['download_url']);
}
```

**Streambare Formate:**
- Video: MP4, WebM
- Audio: MP3, OGG, WAV, MPEG

#### 📂 Datei-Kategorisierung
- **Automatische Sortierung**: Nach Typ gruppiert
- **5 Hauptkategorien**:
  - 📷 **images** - Fotos, Bilder
  - 🎬 **videos** - Videos, Clips
  - 📄 **documents** - PDFs, Word, Excel, Text
  - 🎵 **audio** - Musik, Podcasts, Voice Messages
  - 📦 **other** - Sonstige Dateien

```dart
// Kategorien werden automatisch in separaten Firestore Collections gespeichert:
// - telegram_photos
// - telegram_videos
// - telegram_documents
// - telegram_audio
// - telegram_feed (Text-Posts)
```

#### 💾 Offline-Modus für Medien
- **Lokaler Cache**: Medien werden lokal gespeichert
- **Automatisches Caching**: Bei erstem Download
- **Cache-Verwaltung**: Kontrolle über Speicherplatz
- **Offline-Zugriff**: Medien verfügbar ohne Internet

```dart
// Cache-Verzeichnis: /app_documents/telegram_cache/

// Lokaler Pfad prüfen
final localPath = mediaInfo['local_path'];
final isCached = mediaInfo['is_cached'];

if (isCached && localPath != null) {
  // Datei aus lokalem Cache laden
  final file = File(localPath);
  if (await file.exists()) {
    // Offline verfügbar
  }
}

// Cache löschen
await telegramService.clearCache();
```

#### 🖼️ Galerie pro Topic
- **Grid-Ansicht**: Alle Medien eines Topics in Raster-Layout
- **Filterbar**: Nach Medientyp filtern (Bilder, Videos, Dokumente)
- **Lazy Loading**: Nur sichtbare Items werden geladen
- **Pagination**: Schrittweises Laden großer Galerien

```dart
// Galerie-Daten abrufen
final videos = await telegramService.getVideos();
final photos = await telegramService.getPhotos();
final documents = await telegramService.getDocuments();

// In GridView anzeigen
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
  ),
  itemCount: photos.length,
  itemBuilder: (context, index) {
    final photo = photos[index];
    return Image.network(photo.imageUrl);
  },
);
```

---

## 🗂️ FIRESTORE STRUKTUR

### Hauptsammlungen:

```
telegram_videos/
  {docId}/
    - app_id: string
    - chat_id: string
    - message_id: int
    - text_clean: string
    - media_type: "video"
    - media_files: array
      - telegram_file_id
      - download_url
      - local_path
      - is_cached
      - is_streamable
      - duration
      - width, height
    - topic: string
    - confidence: double
    - keywords: array
    - is_pinned: boolean
    - read_by: array<string>
    - favorite_by: array<string>
    - reply_to: string?
    - thread_id: string?
    - timestamp: timestamp
    
telegram_photos/
  {docId}/ (ähnliche Struktur)
  
telegram_documents/
  {docId}/ (ähnliche Struktur)
  
telegram_audio/
  {docId}/ (ähnliche Struktur)
  
telegram_feed/
  {docId}/ (Text-Posts ohne Medien)
```

### Extended Features Felder:

```dart
'extended_features': {
  'is_pinned': false,
  'pinned_at': Timestamp?,
  'pinned_by': string?,
  'read_by': [],
  'favorite_by': [],
  'reply_to': string?,
  'thread_id': string?,
  'reminder': {
    'user_id': string,
    'remind_at': Timestamp,
    'notified': boolean,
  }?
}
```

---

## 🚀 INTEGRATION IN BESTEHENDE APP

### Schritt 1: Service ersetzen

```dart
// In main.dart oder wo der Service initialisiert wird:

// ALT (V3):
// final telegramService = TelegramService();

// NEU (V4):
import 'services/telegram_service_v4.dart';
final telegramService = TelegramServiceV4();

// Initialisieren
await telegramService.initialize();

// Polling starten
telegramService.startPolling();
```

### Schritt 2: Dependencies prüfen

```yaml
# pubspec.yaml
dependencies:
  cloud_firestore: 5.4.3
  http: ^1.5.0
  path_provider: ^2.1.0  # NEU für lokalen Cache
```

```bash
flutter pub get
```

### Schritt 3: UI-Integration

#### Erweiterte Nachrichtenansicht:

```dart
// lib/widgets/message_card.dart

Widget buildMessageCard(Map<String, dynamic> message, String currentUserId) {
  final isPinned = message['is_pinned'] ?? false;
  final readBy = List<String>.from(message['read_by'] ?? []);
  final favoriteBy = List<String>.from(message['favorite_by'] ?? []);
  final isFavorite = favoriteBy.contains(currentUserId);
  final isRead = readBy.contains(currentUserId);
  
  return Card(
    color: isPinned ? Colors.amber.shade50 : Colors.white,
    child: Column(
      children: [
        // Pin-Badge
        if (isPinned)
          Container(
            color: Colors.amber,
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 16),
                Text('Angepinnt'),
              ],
            ),
          ),
        
        // Nachrichtentext
        ListTile(
          title: Text(message['text_clean'] ?? ''),
          subtitle: Text('${readBy.length} gelesen'),
        ),
        
        // Aktions-Buttons
        ButtonBar(
          children: [
            // Favorit-Toggle
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
              onPressed: () async {
                await telegramService.toggleFavorite(
                  message['app_id'],
                  currentUserId,
                  !isFavorite,
                );
              },
            ),
            
            // Als gelesen markieren
            if (!isRead)
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () async {
                  await telegramService.markAsRead(
                    message['app_id'],
                    currentUserId,
                  );
                },
              ),
            
            // Bearbeiten (nur eigene Nachrichten)
            if (message['author_id'] == currentUserId)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditDialog(message),
              ),
            
            // Löschen (nur eigene Nachrichten)
            if (message['author_id'] == currentUserId)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _confirmDelete(message),
              ),
            
            // Antworten
            IconButton(
              icon: Icon(Icons.reply),
              onPressed: () => _replyToMessage(message),
            ),
            
            // Erinnerung
            IconButton(
              icon: Icon(Icons.alarm),
              onPressed: () => _setReminder(message),
            ),
          ],
        ),
      ],
    ),
  );
}
```

#### Medien-Galerie Screen:

```dart
// lib/screens/media_gallery_screen.dart

class MediaGalleryScreen extends StatelessWidget {
  final String mediaType; // 'images', 'videos', 'documents', 'audio'
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${mediaType} Galerie'),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _getMediaStream(mediaType),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final items = snapshot.data!;
          
          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: mediaType == 'images' ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: mediaType == 'images' ? 1.0 : 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMediaCard(item, mediaType);
            },
          );
        },
      ),
    );
  }
  
  Stream<List<dynamic>> _getMediaStream(String type) {
    switch (type) {
      case 'images':
        return telegramService.getPhotos();
      case 'videos':
        return telegramService.getVideos();
      case 'documents':
        return telegramService.getDocuments();
      case 'audio':
        return telegramService.getAudio();
      default:
        return Stream.value([]);
    }
  }
  
  Widget _buildMediaCard(dynamic item, String type) {
    // Thumbnail anzeigen
    final thumbnailUrl = item.media?.thumbnailUrl ?? item.imageUrl;
    final localPath = item.media?.localPath;
    final isCached = item.media?.isCachedLocally ?? false;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail oder Cached Image
        if (isCached && localPath != null)
          Image.file(File(localPath), fit: BoxFit.cover)
        else if (thumbnailUrl != null)
          Image.network(thumbnailUrl, fit: BoxFit.cover)
        else
          Container(color: Colors.grey[300]),
        
        // Offline-Badge
        if (isCached)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.offline_pin, size: 16, color: Colors.white),
            ),
          ),
        
        // Play-Button für Videos
        if (type == 'videos')
          Center(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }
}
```

---

## 📊 PERFORMANCE & OPTIMIERUNG

### Caching-Strategie:
- **Automatisches Caching** bei erstem Download
- **Cache-Größe limitieren** (z.B. 500MB)
- **LRU (Least Recently Used)** für Cache-Verwaltung
- **Manuelle Löschung** möglich

### Lazy Loading:
- **Pagination**: 50 Items pro Request
- **Infinite Scroll**: Nachladen beim Scrollen
- **Stream-basiert**: Echtzeit-Updates ohne Polling

### Offline-First:
- **Lokaler Cache** hat Priorität
- **Background Sync** bei Netzwerkverbindung
- **Conflict Resolution** bei gleichzeitigen Änderungen

---

## 🔧 KONFIGURATION

### Bot-Token ändern:

```dart
// In telegram_service_v4.dart, Zeile 23:
static const String _botToken = 'DEIN_BOT_TOKEN';
```

### Cache-Verzeichnis anpassen:

```dart
// In _initializeCacheDirectory(), Zeile 162:
_cacheDir = Directory('${appDir.path}/custom_cache_dir');
```

### Polling-Intervall ändern:

```dart
// In startPolling(), Zeile 244:
_pollingTimer = Timer.periodic(
  Duration(seconds: 5), // Standard: 2 Sekunden
  (_) => _pollUpdates(),
);
```

---

## 🐛 DEBUGGING

### Logs aktivieren:

```dart
import 'package:flutter/foundation.dart';

// Logs werden automatisch aktiviert in Debug-Mode
if (kDebugMode) {
  print('Debug-Modus aktiv');
}
```

### Häufige Probleme:

**Problem**: Medien werden nicht gecacht
```dart
// Lösung: Cache-Verzeichnis prüfen
final cacheDir = await getApplicationDocumentsDirectory();
print('Cache-Pfad: ${cacheDir.path}/telegram_cache');
```

**Problem**: Nachrichten werden nicht aktualisiert
```dart
// Lösung: Polling-Status prüfen
print('Polling aktiv: ${telegramService._isPolling}');
print('Letztes Update: ${telegramService._lastSuccessfulPoll}');
```

**Problem**: Firestore-Fehler
```dart
// Lösung: Firestore-Regeln prüfen
// Firestore Console → Rules → Lesen/Schreiben erlauben
```

---

## 📦 MIGRATION VON V3 ZU V4

### Was bleibt gleich:
✅ Firestore-Struktur kompatibel  
✅ Bot-Token & Konfiguration  
✅ Bestehende Daten bleiben erhalten  
✅ UI kann größtenteils gleich bleiben  

### Was ist neu:
🆕 Lokaler Cache-Support  
🆕 Erweiterte Felder in Firestore (read_by, favorite_by, etc.)  
🆕 Neue Methoden (pinMessage, editMessage, etc.)  
🆕 Streaming-Support  

### Migrations-Schritte:

1. **Service-Datei austauschen**
   ```bash
   # V3 umbenennen (Backup)
   mv lib/services/telegram_service.dart lib/services/telegram_service_v3_backup.dart
   
   # V4 aktivieren
   cp lib/services/telegram_service_v4.dart lib/services/telegram_service.dart
   ```

2. **Dependencies aktualisieren**
   ```yaml
   # pubspec.yaml
   dependencies:
     path_provider: ^2.1.0  # NEU hinzufügen
   ```

3. **Flutter pub get**
   ```bash
   flutter pub get
   ```

4. **App neu starten**
   ```bash
   flutter run
   ```

---

## 🎯 ROADMAP (Zukünftige Features)

- [ ] **Reactions**: Emoji-Reaktionen auf Nachrichten
- [ ] **Forward**: Nachrichten weiterleiten
- [ ] **Export**: Backup erstellen
- [ ] **Search**: Volltextsuche über alle Nachrichten
- [ ] **Analytics**: Nutzungsstatistiken
- [ ] **Multi-Bot Support**: Mehrere Bots gleichzeitig
- [ ] **Webhook statt Polling**: Bessere Performance
- [ ] **End-to-End Encryption**: Optional für sensible Daten

---

## 📞 SUPPORT

Bei Fragen oder Problemen:
- 📧 Email: support@example.com
- 💬 Telegram: @your_support_bot
- 🐛 Issues: GitHub Repository

---

**Version**: 4.0.0  
**Letztes Update**: 2024  
**Autor**: Manuel Brandner
