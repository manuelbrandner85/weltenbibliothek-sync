# 🌍 Weltenbibliothek - Alternative Theorien & Verborgenes Wissen

Eine Telegram-ähnliche Social-Mystery-App mit interaktiver Weltkarte. Entdecke verborgenes Wissen, alternative Theorien und tausche dich mit Gleichgesinnten aus.

## 🚀 Live URL

**Hauptanwendung**: https://3000-i1m8akgt437zr75idt4u6-82b888ba.sandbox.novita.ai

### Zugang

- **Login/Register**: `/static/auth.html`
- **Chat-Interface**: `/static/chat.html`
- **Interaktive Karte**: `/` (Hauptseite)

## ✨ Features (Implementiert)

### 🔐 Authentifizierung & User-System
- ✅ Registrierung mit Username, E-Mail, Passwort
- ✅ Login mit JWT-Token-Authentifizierung
- ✅ Geschützte API-Routen mit Middleware
- ✅ User-Profile mit Avatar, Bio, Interessen
- ✅ Online/Offline Status-Tracking

### 💬 Chat-System (Telegram-Style)
- ✅ **Private Chats**: 1-zu-1 Gespräche
- ✅ **Gruppenchats**: Mehrere Mitglieder
- ✅ **Kanäle**: Öffentliche Broadcasts
- ✅ **Real-time Updates**: Polling alle 3 Sekunden
- ✅ **User-Suche**: Finde andere Nutzer
- ✅ **Chat-Liste**: Alle Gespräche auf einen Blick
- ✅ **Message-Threading**: Antworten auf Nachrichten (vorbereitet)
- ✅ **Reactions**: Emoji-Reaktionen (Schema vorhanden)

### 🗺️ Interaktive Mystery-Karte
- ✅ 35+ detaillierte Events weltweit
- ✅ Kategorien: UFOs, Alte Zivilisationen, Alternative Theorien, Mystik
- ✅ Filter nach Kategorie, Event-Typ, Zeitraum
- ✅ Custom Emoji-Marker mit Farbcodierung
- ✅ Popup-Details mit Koordinaten und Beschreibungen
- ✅ Leaflet.js Integration mit Dark Theme

### 📚 Event-Datenbank
**35 bestehende Events + 20 neue (gesamt 55)**

Kategorien:
- **UFOs & Aliens** (20 Events): Roswell, Area 51, Rendlesham Forest, USS Nimitz Tic-Tac, Phoenix Lights, etc.
- **Alte Zivilisationen** (20 Events): Pyramiden von Gizeh, Atlantis, Göbekli Tepe, Stonehenge, Baalbek, Yonaguni, etc.
- **Alternative Theorien** (8 Events): CERN, HAARP, Denver Airport, Bohemian Grove, Untersberg
- **Mystische Orte** (5 Events): Bermuda-Dreieck, Sedona Vortex, Mount Shasta
- **Zeitreisen & Experimente** (2 Events): Montauk Project, Philadelphia-Experiment

**Neue Events (36-55) - Vollständig recherchiert:**
1. Tempel von Baalbek (Megalithische 1.000-Tonnen-Steine)
2. Bosnische Pyramiden (Umstrittene 29.000 Jahre alte Strukturen)
3. Derinkuyu (Unterirdische Stadt für 20.000 Menschen)
4. Yonaguni (Unterwasser-Monument vor Japan)
5. Antikythera-Mechanismus (2.000 Jahre alter Computer)
6. Sacsayhuamán (Perfekt passende 200-Tonnen-Steine)
7. Piri Reis Karte (Zeigt Antarctica eisfrei, 1513)
8. Longyou-Höhlen (2.000 Jahre alte künstliche Höhlen)
9. Newgrange (5.000 Jahre alt, älter als Pyramiden)
10. Teotihuacán (Pyramiden mit Quecksilber)
11. Betty & Barney Hill Entführung (1961, erste dokumentierte)
12. Westall UFO Encounter (200 Zeugen, Australien 1966)
13. Travis Walton Entführung (5 Tage verschwunden, 1975)
14. Iranian Air Force UFO (F-4 Jets, Teheran 1976)
15. JAL Flight 1628 (Jumbo-Jet, Alaska 1986)
16. Belgian UFO Wave (F-16 Verfolgung, 1989-1990)
17. USS Nimitz Tic-Tac (Pentagon bestätigt, 2004)
18. Ariel School (62 Kinder, Zimbabwe 1994)
19. O'Hare Airport UFO (United Airlines, Chicago 2006)
20. Rendlesham Forest (Britischer Roswell, 1980)

## 🏗️ Technologie-Stack

### Backend
- **Hono v4** - Lightweight Web Framework
- **Cloudflare Workers** - Edge Runtime
- **Cloudflare D1** - SQLite Database (weltenbibliothek_db_v2)
- **Cloudflare R2** - Object Storage (weltenbibliothek-media)
- **TypeScript** - Type-safe Development
- **JWT** - Authentication Tokens

### Frontend
- **Vanilla JavaScript** - No framework overhead
- **Leaflet.js 1.9.4** - Interactive Maps
- **TailwindCSS** - Utility-first CSS
- **FontAwesome 6.4** - Icons
- **Axios** - HTTP Client

### Database Schema
```sql
-- Core Tables
users (id, username, email, password_hash, display_name, avatar_url, bio, interests, status)
chats (id, chat_type, title, description, creator_id, member_count)
chat_members (id, chat_id, user_id, role, joined_at, last_read_message_id)
messages (id, chat_id, sender_id, content, message_type, reply_to_message_id)
message_reactions (id, message_id, user_id, reaction)

-- Events & Interactions
events (id, title, description, latitude, longitude, category, event_type, year, full_description, sources, keywords)
event_comments (id, event_id, user_id, parent_comment_id, content)
event_bookmarks (id, event_id, user_id, notes)
event_views (id, event_id, user_id, view_duration)

-- Notifications
notifications (id, user_id, notification_type, title, body, data, is_read)
push_subscriptions (id, user_id, endpoint, auth_key, device_type)
```

## 🔗 API-Endpunkte

### Authentication
- `POST /api/auth/register` - Neues Konto erstellen
- `POST /api/auth/login` - Anmelden
- `GET /api/auth/me` - Aktueller User (geschützt)
- `PUT /api/auth/profile` - Profil aktualisieren (geschützt)
- `POST /api/auth/logout` - Abmelden (geschützt)

### Chat
- `GET /api/chats` - Alle Chats des Users (geschützt)
- `POST /api/chats` - Neuen Chat erstellen (geschützt)
- `GET /api/chats/:id/messages` - Nachrichten laden (geschützt)
- `POST /api/chats/:id/messages` - Nachricht senden (geschützt)
- `GET /api/chats/:id/members` - Chat-Mitglieder (geschützt)
- `GET /api/users/search?q=...` - User suchen (geschützt)

### Events & Map
- `GET /api/events` - Alle Events (mit Filtern: category, type, year_from, year_to)
- `GET /api/events/:id` - Einzelnes Event mit Details
- `GET /api/events/categories` - Event-Kategorien mit Counts
- `GET /api/events/types` - Event-Typen mit Counts

### Documents
- `GET /api/search?q=...` - Volltext-Suche in Dokumenten
- `GET /api/files/:path` - R2-Datei-Zugriff
- `POST /api/upload` - Datei hochladen zu R2

## 🎨 UI-Komponenten

### Chat-Interface (Telegram-Style)
- **Sidebar**: Chat-Liste mit Suche, Tabs (Chats/Karte), Neuer-Chat-Button
- **Main Area**: 
  - Chat-Header mit Avatar und Status
  - Messages-Container mit Auto-Scroll
  - Message-Input mit Attachment-Button
- **Modals**: New Chat mit User-Suche
- **Design**: Dark Theme, Glassmorphismus, Gold-Akzente (#ffd700)

### Map-Interface
- **Top Bar**: Logo, Search, Filter-Button, Chat-Button, Auth-Button
- **Map**: Vollbild Leaflet-Karte mit Custom Markers
- **Side Panel**: Filter (Kategorien, Event-Typen, Zeitraum)
- **Bottom Nav**: Map, List, Documents, Timeline (Coming Soon)
- **Popups**: Event-Details beim Marker-Click

### Auth-Interface
- **Tabs**: Login / Registrieren
- **Login Form**: Username/Email, Passwort
- **Register Form**: Username, Email, Anzeigename, Passwort
- **Design**: Gradient Background, Glassmorphism, Responsive
- **Validation**: Client & Server-Side

## 📱 User Experience

### Flow: Neue User
1. Öffne App → Sehe Karte (ungeschützt)
2. Klicke "Login" → Weiterleitung zu `/static/auth.html`
3. Registriere Konto → Token gespeichert
4. Automatische Weiterleitung zur Karte
5. Klicke "Chat" → Öffne `/static/chat.html`
6. Starte neuen Chat → Suche User → Sende Messages

### Flow: Bestehende User
1. Öffne App → Auto-Login (Token im LocalStorage)
2. Sehe Username statt "Login"
3. Direkter Zugang zu allen Features
4. Click auf Username → Logout

## 🚧 Features in Entwicklung

### Geplant für nächste Schritte:
- [ ] **WebSocket/Durable Objects** für Live-Chat (aktuell: Polling)
- [ ] **Push-Notifications** mit Cloudflare (ersetzt Firebase)
- [ ] **Event-Detail-Modal** mit vollständigen Texten und Quellen
- [ ] **Event-Kommentare** und Diskussionen
- [ ] **Timeline-Ansicht** für chronologische Navigation
- [ ] **List-Ansicht** für Event-Tabelle
- [ ] **Documents-Ansicht** für Bibliothek
- [ ] **Weitere 100 Events** (Ziel: 155 total)

### Zukünftige Features:
- [ ] Audio/Video-Nachrichten (Agora RTC)
- [ ] YouTube-Integration in Events
- [ ] Datei-Sharing zwischen Usern
- [ ] Event-Bookmarks mit persönlichen Notizen
- [ ] User-Reputation-System
- [ ] Themen-basierte Kanäle
- [ ] Event-Proximity-Benachrichtigungen

## 🛠️ Development

### Lokale Entwicklung
```bash
# Dependencies installieren
npm install

# Migrationen anwenden
npm run db:migrate:local

# Entwicklungsserver starten
npm run dev:sandbox

# Build für Production
npm run build
```

### PM2 Commands
```bash
pm2 list                      # Services anzeigen
pm2 logs weltenbibliothek     # Logs anzeigen (--nostream)
pm2 restart weltenbibliothek  # Neustart
pm2 delete weltenbibliothek   # Stoppen
```

### Git Workflow
```bash
git add .
git commit -m "Feature description"
git push origin main
```

### Deployment zu Cloudflare Pages
```bash
# Build & Deploy
npm run deploy:prod

# Nur Build
npm run build

# Preview lokal
npm run preview
```

## 📊 Projekt-Struktur

```
webapp/
├── src/
│   ├── index.tsx           # Hauptanwendung (Hono-App + Map HTML)
│   └── auth.ts             # Auth-Utilities (JWT, Hashing)
├── public/
│   └── static/
│       ├── auth.html       # Login/Register-Seite
│       ├── chat.html       # Chat-Interface
│       ├── chat.js         # Chat-Logic
│       └── app.js          # Map-Logic (derzeit leer, inline im HTML)
├── migrations/
│   ├── 0001_create_documents.sql
│   ├── 0002_create_events.sql
│   ├── 0003_create_users.sql
│   ├── 0004_create_chats.sql
│   ├── 0005_create_messages.sql
│   ├── 0006_create_notifications.sql
│   ├── 0007_create_event_interactions.sql
│   └── 0008_extend_events.sql
├── seed_events.sql         # 35 originale Events
├── seed_batch1_events.sql  # 20 neue Events (36-55)
├── ecosystem.config.cjs    # PM2-Konfiguration
├── wrangler.jsonc          # Cloudflare-Konfiguration
├── vite.config.ts          # Vite Build-Konfiguration
├── package.json            # Dependencies & Scripts
└── README.md               # Diese Datei
```

## 🎯 Projekt-Philosophie

### Verborgenes Wissen & Alternative Theorien
Weltenbibliothek ist eine Plattform für den Austausch von Wissen, das oft unterdrückt oder ignoriert wird:
- **Alternative Geschichtsschreibung**: Hinterfrage die offizielle Narrative
- **Unerklärliche Phänomene**: UFOs, Zeitanomalien, mystische Orte
- **Vergessene Zivilisationen**: Antike Technologien und Bauwerke
- **Moderne Geheimnisse**: Geheimgesellschaften, Experimente, Vertuschungen

Wir verwenden Begriffe wie "Alternative Theorien", "Verborgenes Wissen" und "Unterdrückte Geschichte" statt polemischer Bezeichnungen.

### Community-First
- **Respektvoller Austausch**: Diskutiere, ohne zu diskreditieren
- **Quellenbasiert**: Referenzen zu Büchern, Dokumenten, Zeugenaussagen
- **Open-Minded**: Kritisches Denken ohne Dogmatismus
- **Wissensnetzwerk**: Gemeinsam die Wahrheit suchen

## 🔮 Vision

Weltenbibliothek wird zur **größten deutschsprachigen Community** für verborgenes Wissen:
- **155 detaillierte Events** mit Quellen und Hintergründen
- **Live-Diskussionen** zu jedem Event
- **User-Generated Content**: Eigene Theorien und Entdeckungen teilen
- **Multimedia-Archiv**: Dokumente, Videos, Audio-Aufnahmen
- **Globales Netzwerk**: Verbindung zu Forschern weltweit

## 📝 Status

- **Version**: 0.3.0 (Beta)
- **Letztes Update**: 2025-11-16
- **Aktive Features**: Auth, Chat, Map, 55 Events
- **In Entwicklung**: Live-Chat (WebSocket), Push-Notifications, Event-Details-Modal
- **Deployment**: Sandbox (Development)

## 👥 Credits

- **Framework**: Hono by Yusuke Wada
- **Maps**: Leaflet.js by Vladimir Agafonkin
- **Tiles**: CartoDB Dark Matter
- **Icons**: FontAwesome
- **Event-Recherche**: Diverse Quellen (siehe Event-Descriptions)

## 📄 Lizenz

Dieses Projekt ist für Forschungs- und Bildungszwecke. Alle Event-Informationen sind aus öffentlich zugänglichen Quellen zusammengetragen.

---

**🌟 Entdecke die Wahrheit. Teile dein Wissen. Hinterfrage alles.**
