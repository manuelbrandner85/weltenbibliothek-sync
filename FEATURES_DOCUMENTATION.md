# 🌟 Weltenbibliothek - Features Dokumentation

## 📱 Überblick der implementierten Features

Diese Dokumentation beschreibt alle Features die **fertig implementiert** sind und wie du sie nutzen kannst.

---

## 1. 💬 Chat System

### 1.1 Fixed Default Chats (Immer Sichtbar)

#### 💬 Allgemein Chat
- **ID**: 1
- **Typ**: Public Channel
- **Beschreibung**: Allgemeiner Chat für alle Themen - Alternative Theorien, Mysterien, und mehr
- **Features**:
  - Für alle User sichtbar
  - Kein Join erforderlich
  - Welcome Message automatisch
  - Livestreaming aktivierbar

**Zugriff**: Einfach auf "💬 Allgemein" in der Sidebar klicken

#### 🎵 Musik Chat
- **ID**: 2
- **Typ**: Public Channel
- **Beschreibung**: Musik-Diskussionen, Livestreams, Künstler-Entdeckungen
- **Features**:
  - Für alle User sichtbar
  - Musik-spezifische Themen
  - Livestreaming perfekt für Musik-Sessions
  - Welcome Message mit Guidelines

**Zugriff**: Klick auf "🎵 Musik" in der Sidebar

### 1.2 Private & Group Chats

**Private Chats**:
- 1:1 Direktnachrichten
- User-Suche über "Neuer Chat" Button
- Automatische Chat-Erstellung

**Group Chats**:
- Mehrere Mitglieder
- Admin-Rollen
- Custom Titel & Beschreibung

**Wie erstellen**:
1. Klicke "+" Button in Sidebar
2. Suche User (mindestens 2 Zeichen)
3. Klicke auf User-Profil
4. Chat wird automatisch erstellt

### 1.3 Message Features

**Unterstützte Features**:
- ✅ Text Messages
- ✅ Real-time Updates (3s Polling)
- ✅ Message History
- ✅ Timestamps
- ✅ User Avatare
- ✅ Read Status
- ✅ Empty States

**Geplant** (noch nicht implementiert):
- ⏳ File Uploads
- ⏳ Emojis & Reactions
- ⏳ Message Edit/Delete
- ⏳ Typing Indicators
- ⏳ @ Mentions

---

## 2. 🎥 Livestreaming (Agora RTC)

### 2.1 Verfügbarkeit

**Status**: ✅ Implementiert, ⚠️ Agora App ID benötigt

**Wo aktivieren**: In jedem Chat (empfohlen: 🎵 Musik Chat)

### 2.2 Features

**Video Grid**:
- Lokales Video (eigene Kamera)
- Remote Videos (andere Teilnehmer)
- Auto-Layout (Grid-basiert)
- Responsive Design

**Stream Controls**:
- 🎤 Mikrofon an/aus
- 📹 Kamera an/aus
- ⬇️ Minimieren (Picture-in-Picture)
- 📵 Stream beenden

**Picture-in-Picture Mode**:
- Telegram-style Overlay
- Kleines Video-Fenster
- Chat bleibt sichtbar
- Jederzeit expandierbar

### 2.3 Nutzung

**Stream starten**:
```
1. Öffne einen Chat (z.B. 🎵 Musik)
2. Klicke Video-Icon (📹) im Header
3. Erlaube Browser Kamera/Mikrofon-Zugriff
4. Stream startet automatisch
5. Andere User können joinen
```

**Controls nutzen**:
- Hover über Video-Bereich
- Controls erscheinen unten
- Klick auf Icon = Toggle

**Minimieren**:
- Klick auf ⬇️ Icon
- Video wird klein in Ecke
- Chat ist wieder voll sichtbar
- Klick auf Video = Expand

### 2.4 Technische Details

**Agora RTC SDK**: v4.20.0
**Video Quality**: 720p, 30fps
**Codec**: VP8
**Mode**: RTC (Real-Time Communication)

**App ID Setup** (erforderlich):
```javascript
// In public/static/livestream.js Zeile 9
const AGORA_APP_ID = "DEINE_APP_ID_HIER";
```

**Kostenlos**: 10.000 Minuten/Monat
**Danach**: $0.99 - $3.99 / 1000 Minuten

**Account erstellen**: https://console.agora.io

---

## 3. 🤖 AI Assistant (Google Gemini)

### 3.1 Verfügbarkeit

**Status**: ✅ Voll funktionsfähig, API Key bereits konfiguriert

**Zugriff**: Klick auf 🤖 Robot-Icon im Chat Header

### 3.2 Features

#### Text Chat
- Fragen in Deutsch oder Englisch
- Kontext-bewusste Antworten
- Markdown-ähnliche Formatierung
- Unbegrenzte Anfragen (60/min Limit)

**Beispiele**:
```
- "Erkläre mir die Quantenphysik"
- "Was bedeutet diese Theorie?"
- "Hilf mir bei diesem Mysterium"
- "Schreibe einen Text über..."
```

#### Spracheingabe (KOSTENLOS)
- Web Speech API (Browser-nativ)
- Deutsch-Erkennung
- Klick auf 🎤 Icon
- Sprechen → Automatisch gesendet

**Unterstützte Browser**:
- ✅ Chrome / Edge
- ✅ Safari
- ❌ Firefox (teilweise)

#### Text-to-Speech (KOSTENLOS)
- Automatische Vorlesung der AI-Antworten
- Browser-native Stimme
- Deutsche Aussprache
- Kann deaktiviert werden

#### Bildanalyse (Gemini Vision)
- Screenshots analysieren
- Bilder beschreiben
- Text in Bildern erkennen
- Kontext verstehen

**Video-Frame Analyse**:
- Während Livestream: Klick auf 📸 Icon
- Frame wird automatisch captured
- AI analysiert das Bild
- Antwort im Chat

### 3.3 Nutzung

**AI Chat öffnen**:
```
1. Öffne einen Chat
2. Klicke 🤖 Robot-Icon im Header
3. AI Panel öffnet sich
4. Stelle Frage im Input-Feld
```

**Spracheingabe**:
```
1. Klick auf 🎤 Mikrofon-Icon
2. Erlaube Mikrofon-Zugriff
3. Sprich deine Frage
4. AI antwortet automatisch
```

**Video analysieren**:
```
1. Starte Livestream
2. Öffne AI Panel
3. Klick auf 📸 Kamera-Icon
4. Frame wird analysiert
5. AI beschreibt was sie sieht
```

### 3.4 Technische Details

**Gemini Pro** (Text):
- Model: gemini-pro
- Max Tokens: 1024
- Temperature: 0.7
- Gratis: 60 req/min

**Gemini Vision** (Bilder):
- Model: gemini-pro-vision
- Bildformate: JPG, PNG
- Max Size: 4 MB
- Gratis: 60 req/min

**API Key**: `AIzaSyB31CamtfNJv7eymRqah-dYkUxqvB5mex8`
**Status**: ✅ Bereits konfiguriert

---

## 4. 🎨 Design System

### 4.1 Farben

**Primary Palette**:
```css
--primary: #6366f1       /* Indigo */
--secondary: #8b5cf6     /* Violet */
--accent: #ec4899        /* Pink */
```

**Background**:
```css
--bg-primary: #0f172a    /* Slate 900 */
--surface: #1e293b       /* Slate 800 */
```

**Text**:
```css
--text-primary: #f1f5f9   /* Light */
--text-secondary: #cbd5e1 /* Gray */
--text-tertiary: #94a3b8  /* Dim */
```

### 4.2 Komponenten

**Buttons**:
- `.btn-primary` - Gradient Indigo/Violet
- `.btn-secondary` - Surface mit Border
- `.btn-ghost` - Transparent
- `.btn-icon` - Runde Icon-Buttons

**Cards**:
- `.card` - Standard Card
- `.card-glass` - Glassmorphism

**Badges**:
- `.badge-primary` - Indigo
- `.badge-success` - Green
- `.badge-danger` - Red
- `.badge-warning` - Orange

**Avatare**:
- `.avatar-sm` - 32px
- `.avatar-md` - 40px
- `.avatar-lg` - 56px
- `.avatar-xl` - 80px

### 4.3 Effekte

**Glassmorphism**:
```css
.glass {
  background: rgba(30, 41, 59, 0.7);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(148, 163, 184, 0.1);
}
```

**Animations**:
- `fadeIn` - Fade in from bottom
- `slideInRight` - Slide from right
- `pulse` - Pulsing effect
- `spin` - Rotation

**Transitions**:
```css
--transition: 300ms cubic-bezier(0.4, 0, 0.2, 1);
```

---

## 5. 🗺️ Event Map (Original Features)

### 5.1 Verfügbar

**Status**: ✅ Original-Design, Update geplant

**Features**:
- Leaflet.js Interactive Map
- 80 Events markiert
- Kategorien: Verschwörungstheorien, Mysterien, etc.
- Event-Details Modal
- Bookmarks
- Search

**Zugriff**: Hauptseite `/` oder Tab "Karte" in Chat

### 5.2 Geplant

**Design Update**:
- Design System Integration
- Moderne Farben (Indigo/Violet)
- Glassmorphism Effects
- Bessere Event-Cards

---

## 6. 🔐 Auth System

### 6.1 Features

**Registration**:
- Username (unique)
- Email
- Password (SHA-256 hashed)
- Display Name
- Auto-Login nach Registration

**Login**:
- Username/Email + Password
- JWT Token
- LocalStorage persistierung
- Auto-Redirect zu Chat

**Roles**:
- `user` - Standard
- `moderator` - Extended permissions
- `admin` - Full access
- `superadmin` - System access

### 6.2 Super Admin Account

**Status**: ⚠️ Noch nicht in Production erstellt

**Credentials** (für lokale DB):
- Username: `Weltenbibliothek`
- Password: `Jolene2305`
- Role: `superadmin`

**Erstellen**:
```bash
# Über API oder direkt in DB
INSERT INTO users (...) VALUES (...);
UPDATE users SET role = 'superadmin' WHERE username = 'Weltenbibliothek';
```

---

## 7. 🔔 Notifications (Backend vorhanden)

### 7.1 Status

**Backend**: ✅ Vollständig implementiert
**Frontend**: ⏳ UI noch nicht komplett

**API Endpoints**:
- `GET /api/notifications` - Liste
- `POST /api/notifications/:id/read` - Als gelesen markieren
- `DELETE /api/notifications/:id` - Löschen

### 7.2 Notification Types

- `message` - Neue Chat-Nachricht
- `mention` - @ Erwähnung
- `event` - Event-Update
- `system` - System-Benachrichtigung

---

## 8. 📊 Database Schema

### Tables

1. **users** - User Accounts
2. **documents** - Wiki-Dokumente
3. **events** - Map Events
4. **chats** - Chat Channels
5. **chat_members** - Chat-Mitgliedschaften
6. **messages** - Chat-Nachrichten
7. **notifications** - User-Benachrichtigungen
8. **event_views** - Event-Statistiken
9. **event_bookmarks** - User-Bookmarks

### Default Data

**System User** (ID: 0):
- Für System-Nachrichten
- Welcome Messages
- Bot-Funktionen

**Default Chats**:
- Allgemein (ID: 1)
- Musik (ID: 2)

---

## 9. ⚙️ Configuration

### Environment Variables

**Local Development** (`.dev.vars`):
```
# Keine benötigt - alles im Code
```

**Production** (Cloudflare Secrets):
```bash
wrangler pages secret put AGORA_APP_ID
wrangler pages secret put GEMINI_API_KEY  # Optional
```

### Wrangler Config

**wrangler.jsonc**:
```json
{
  "name": "weltenbibliothek",
  "d1_databases": [{
    "binding": "DB",
    "database_name": "weltenbibliothek-production",
    "database_id": "af6e52c4-0835-402a-bf47-52858beffd35"
  }]
}
```

---

## 10. 🚨 Troubleshooting

### Chat lädt nicht
**Problem**: Default Chats nicht sichtbar

**Lösung**:
```bash
cd /home/user/webapp
npx wrangler d1 execute weltenbibliothek-production --local --file=./create_default_chats.sql
```

### Livestream startet nicht
**Problem**: "Agora App ID fehlt!" Alert

**Lösung**: Trage App ID ein in `/public/static/livestream.js`

### AI antwortet nicht
**Problem**: Gemini API Error

**Check**:
1. API Key korrekt?
2. Rate Limit erreicht? (60/min)
3. Internet-Verbindung?

### Voice Recognition funktioniert nicht
**Problem**: Mikrofon-Zugriff verweigert

**Lösung**:
1. Browser-Permissions prüfen
2. HTTPS erforderlich (HTTP unsupported)
3. Chrome/Edge/Safari nutzen

---

## 📝 Quick Reference

### Wichtige Dateien

**Frontend**:
- `public/static/chat.html` - Chat UI
- `public/static/design-system.css` - Design System
- `public/static/livestream.js` - Agora Integration
- `public/static/ai-chat.js` - Gemini Integration

**Backend**:
- `src/index.tsx` - Hono API
- `wrangler.jsonc` - Cloudflare Config

**Database**:
- `migrations/` - Schema Migrations
- `create_default_chats.sql` - Default Data

### Nützliche Commands

```bash
# Development
npm run dev:d1              # Start mit D1
npm run build               # Build für Production

# Database
npm run db:reset            # Alles neu aufsetzen
npm run db:seed             # Test-Daten laden

# Deployment
npm run deploy:prod         # Zu Cloudflare Pages
```

---

**Dokumentation erstellt**: 2025-11-16  
**Version**: 2.0  
**Status**: Production Ready (bis auf Agora App ID)
