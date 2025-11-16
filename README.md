# 🌍 Weltenbibliothek - Interaktive Karte

**Die ultimative interaktive Weltkarte für verborgenes Wissen, alte Zivilisationen und mysteriöse Ereignisse**

Eine moderne Web-Anwendung mit **interaktiver Leaflet-Karte**, Event-Markern, Filtern und umfangreicher Dokumenten-Bibliothek.

## 🌐 Live URLs

- **Sandbox**: https://3000-i1m8akgt437zr75idt4u6-82b888ba.sandbox.novita.ai
- **Produktion** (nach Deployment): `https://webapp.pages.dev`

## ✨ Haupt-Features

### 🗺️ Interaktive Weltkarte
- ✅ **Leaflet.js Integration** - Flüssiges Zoomen & Panning
- ✅ **Dunkles Karten-Theme** (CartoDB Dark Matter)
- ✅ **35 mysteriöse Ereignisse** weltweit als Marker
- ✅ **Custom Icons** - Emoji-basierte Marker für jeden Event-Typ
- ✅ **Info-Popups** - Detaillierte Informationen beim Klick
- ✅ **Responsive Design** - Funktioniert auf Desktop & Mobile

### 🎯 Event-Marker-System
**35 historische Ereignisse** mit präzisen Koordinaten:

**Alte Zivilisationen:**
- 🔺 Große Pyramide von Gizeh (Ägypten)
- 🌊 Atlantis (vermutete Lage bei Azoren)
- 🗿 Stonehenge (UK)
- 🛕 Angkor Wat (Kambodscha)
- 🗿 Osterinsel Moai-Statuen
- 🛕 Göbekli Tepe (Türkei)

**UFO & Aliens:**
- 🛸 Area 51 (Nevada, USA)
- 💥 Roswell UFO-Absturz (New Mexico)
- 🛸 Rendlesham Forest (UK)
- 💡 Phoenix Lights (Arizona)
- 💥 Tunguska-Ereignis (Sibirien)

**Geheimgesellschaften:**
- 🎭 Bohemian Grove (Kalifornien)
- ✈️ Denver Airport (Colorado)
- 🏛️ Pentagon (Virginia)
- ⛪ Vatikan (Rom)
- 💀 Skull & Bones HQ (Yale)

**Geheimdienste & Experimente:**
- 📡 Montauk Air Force Station
- ⛴️ Philadelphia Naval Shipyard
- 🕵️ CIA Hauptquartier Langley
- ☣️ Dugway Proving Ground

**...und viele mehr!**

### 🔍 Filter & Such-System
- ✅ **Echtzeit-Suche** - Suche nach Titel, Beschreibung, Ort
- ✅ **Kategorien-Filter** - 11 Kategorien (UFOs, Alte Zivilisationen, etc.)
- ✅ **Event-Typ-Filter** - ancient, ufo, conspiracy, mystery
- ✅ **Zeitraum-Filter** - Von/Bis Jahr
- ✅ **Kombinerbare Filter** - Mehrere Filter gleichzeitig aktiv

### 🎨 Modern UI/UX
- ✅ **Top Bar** - Logo, Suchfeld, Filter-Button
- ✅ **Bottom Navigation** - Karte, Liste, Dokumente, Timeline
- ✅ **Side Panel** - Ausklappbare Filter-Sidebar
- ✅ **Dark Theme** - Mystisches dunkles Design
- ✅ **Glow-Effekte** - Goldene Akzente
- ✅ **Responsive Layout** - Mobile-First Design

### 📚 Dokumenten-Bibliothek
- ✅ **20 Dokumente** über Verschwörungstheorien
- ✅ **17 Kategorien** - Von Illuminaten bis Zeitreisen
- ✅ **Volltext-Suche** - FTS5 SQLite Integration
- ✅ **Verknüpfung** - Events können Dokumente referenzieren

## 🗄️ Datenbank-Architektur

### Cloudflare D1 Datenbank
**Database Name**: `weltenbibliothek_db_v2`  
**Database ID**: `6da1abb7-8ebf-40cb-bc7e-1656b35f2880`

### Events Table
```sql
CREATE TABLE events (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  category TEXT,
  event_type TEXT,
  year INTEGER,
  date_text TEXT,
  icon_type TEXT,
  image_url TEXT,
  related_document_id INTEGER
)
```

**Aktueller Bestand:**
- **35 Events** auf der Weltkarte
- **11 Kategorien** (UFOs, Geheimgesellschaften, etc.)
- **4 Event-Typen** (ancient, ufo, conspiracy, mystery)
- **Zeitspanne**: 9600 v.Chr. bis Heute

### Documents Table
```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT,
  category TEXT,
  description TEXT,
  file_path TEXT,
  created_at DATETIME
)
```

**Aktueller Bestand:**
- **20 Dokumente**
- **17 Kategorien**

### Cloudflare R2 Storage
**Bucket**: `weltenbibliothek-media`  
- PDF-Dokumente
- Bilder & Icons
- Event-Medien

## 🛠️ Tech Stack

### Backend
- **Hono v4** - Lightweight Edge Framework
- **Cloudflare Workers** - Serverless Runtime
- **Cloudflare D1** - SQLite Datenbank
- **Cloudflare R2** - Object Storage
- **TypeScript** - Type Safety

### Frontend
- **Leaflet.js 1.9.4** - Interactive Maps
- **Vanilla JavaScript** - No Framework Bloat
- **TailwindCSS** - Utility-First CSS
- **FontAwesome** - Icons
- **Axios** - HTTP Client

### Development
- **Vite** - Build Tool
- **PM2** - Process Manager
- **Wrangler** - Cloudflare CLI
- **Git** - Version Control

## 📋 API Endpoints

### Map & Events API

#### `GET /api/events`
Alle Events für die Karte abrufen.

**Query Parameters:**
- `category` - Filter nach Kategorie
- `type` - Filter nach Event-Typ
- `year_from` - Minimum Jahr
- `year_to` - Maximum Jahr

**Response:**
```json
{
  "success": true,
  "events": [
    {
      "id": 1,
      "title": "Die Große Pyramide von Gizeh",
      "latitude": 29.9792,
      "longitude": 31.1342,
      "category": "Alte Zivilisationen",
      "event_type": "ancient",
      "year": -2560,
      "icon_type": "pyramid"
    }
  ]
}
```

#### `GET /api/events/:id`
Einzelnes Event mit Details.

#### `GET /api/events/categories`
Alle verfügbaren Kategorien mit Anzahl.

#### `GET /api/events/types`
Alle Event-Typen mit Anzahl.

### Documents API

#### `GET /api/search`
Dokumente durchsuchen.

**Query Parameters:**
- `q` - Suchbegriff
- `category` - Kategorie
- `limit` - Anzahl Ergebnisse
- `offset` - Pagination

#### `GET /api/documents/:id`
Einzelnes Dokument abrufen.

#### `GET /api/categories`
Dokument-Kategorien.

#### `GET /api/stats`
Statistiken über Dokumente und Events.

**Response:**
```json
{
  "total_documents": 20,
  "total_events": 35,
  "categories": [...]
}
```

### File Management

#### `GET /api/files/:path`
Datei aus R2 Storage laden.

#### `POST /api/upload`
Datei hochladen (Multipart Form Data).

## 🚀 Lokale Entwicklung

### Setup
```bash
# 1. Dependencies installieren
npm install

# 2. Migrationen anwenden
npx wrangler d1 migrations apply weltenbibliothek_db_v2 --local

# 3. Events laden
npx wrangler d1 execute weltenbibliothek_db_v2 --local --file=./seed_events.sql

# 4. Dokumente laden
npx wrangler d1 execute weltenbibliothek_db_v2 --local --file=./seed.sql

# 5. Build
npm run build

# 6. Server starten
pm2 start ecosystem.config.cjs
```

### Entwicklung
```bash
# Status prüfen
pm2 list

# Logs ansehen
pm2 logs weltenbibliothek --nostream

# Neustart nach Code-Änderungen
pm2 restart weltenbibliothek

# Datenbank-Konsole
npx wrangler d1 execute weltenbibliothek_db_v2 --local
```

## 📦 Deployment

### Cloudflare Pages
```bash
# 1. Setup API Key
# Call setup_cloudflare_api_key first

# 2. Migrationen auf Produktion
npx wrangler d1 migrations apply weltenbibliothek_db_v2

# 3. Daten laden
npx wrangler d1 execute weltenbibliothek_db_v2 --file=./seed_events.sql
npx wrangler d1 execute weltenbibliothek_db_v2 --file=./seed.sql

# 4. Deployment
npm run deploy:prod
```

## 🗂️ Projekt-Struktur

```
webapp/
├── src/
│   └── index.tsx           # Hono Backend mit Map & Documents API
├── public/
│   └── static/
│       ├── app.js          # Leaflet Map Frontend
│       ├── app_icon.png    # App Icon
│       └── style.css       # Custom Styles
├── migrations/
│   ├── 0001_create_documents.sql
│   └── 0002_create_events.sql
├── seed.sql                # 20 Dokumente
├── seed_events.sql         # 35 Weltkarten-Events
├── ecosystem.config.cjs    # PM2 Config
├── wrangler.jsonc          # Cloudflare Config
├── package.json            # Dependencies
└── README.md               # Diese Datei
```

## 🎨 UI-Komponenten

### Top Bar
- **Logo** - Weltenbibliothek Icon & Name
- **Suchfeld** - Echtzeit-Event-Suche
- **Filter-Button** - Öffnet Side Panel

### Map Container
- **Leaflet Map** - Vollbild, interaktiv
- **Custom Markers** - Emoji-Icons mit Glow
- **Popups** - Event-Details beim Klick

### Side Panel (Filter)
- **Kategorien** - 11 Filter-Chips
- **Event-Typen** - 4 Typ-Filter
- **Zeitraum** - Von/Bis Jahr Eingabe
- **Aktionen** - Anwenden & Zurücksetzen

### Bottom Navigation
- **Karte** - Haupt-Ansicht (aktiv)
- **Liste** - Event-Liste (coming soon)
- **Dokumente** - Bibliothek (coming soon)
- **Timeline** - Zeitstrahl (coming soon)

## 🎯 Event-Kategorien

1. **Alte Zivilisationen** (8 Events) - Pyramiden, Stonehenge, Atlantis
2. **UFOs** (6 Events) - Area 51, Roswell, Phoenix Lights
3. **Geheimgesellschaften** (4 Events) - Illuminaten, Bohemian Grove
4. **Verschwörungen** (3 Events) - Denver Airport, Pentagon
5. **Zeitreisen** (3 Events) - Philadelphia, Montauk
6. **Geheimdienste** (2 Events) - CIA, MK-Ultra
7. **Hohle Erde** (3 Events) - Mount Shasta, Nordpol
8. **Mystik** (2 Events) - Sedona Vortex
9. **Klimamanipulation** (2 Events) - Chemtrails, HAARP
10. **Paralleluniversen** (3 Events) - CERN, Bermuda-Dreieck
11. **Alte Astronauten** (2 Events) - Nazca, Anunnaki

## 📊 Statistiken

- **Total Events**: 35
- **Total Documents**: 20
- **Kategorien**: 11
- **Event-Typen**: 4
- **Zeitspanne**: 9600 v.Chr. - Heute
- **Geografische Abdeckung**: Weltweit
- **Code-Zeilen**: ~1000 (TypeScript + JavaScript)

## 🔮 Kommende Features

### In Entwicklung:
- ⏳ **Listen-Ansicht** - Tabellarische Event-Liste
- ⏳ **Timeline-Ansicht** - Chronologischer Zeitstrahl
- ⏳ **Dokument-Detail-Seiten** - Vollständige Dokument-Ansicht
- ⏳ **YouTube-Integration** - Embedded Videos
- ⏳ **Cloudflare Upload** - Neue Events hinzufügen

### Geplant:
- 📱 **Progressive Web App** - Offline-Funktionalität
- 🔔 **Cloudflare Notifications** - Event-Benachrichtigungen
- 🌙 **Theme-Wechsel** - Hell/Dunkel-Modus
- 🎥 **Media-Galerie** - Bilder & Videos zu Events
- 📍 **GPS-Integration** - Standort-basierte Events
- 🗣️ **Multi-Language** - Deutsch, English, weitere

## 🎭 Icon-Mapping

Jeder Event-Typ hat sein eigenes Emoji-Icon:

| Icon | Typ | Beispiel |
|------|-----|----------|
| 🔺 | pyramid | Pyramiden |
| 🌊 | atlantis | Atlantis |
| 🗿 | stone/moai | Stonehenge, Osterinsel |
| 🛸 | ufo | UFO-Sichtungen |
| 💥 | crash/explosion | Roswell, Tunguska |
| 🎭 | cult | Geheimgesellschaften |
| 🕵️ | cia | Geheimdienste |
| ⛰️ | mountain | Mount Shasta |
| 📡 | radar/station | Montauk, HAARP |
| ⚛️ | cern | Teilchenbeschleuniger |

## 🔐 Sicherheit

- **API-Schutz** - CORS konfiguriert
- **SQL Injection** - Prepared Statements
- **Input Validation** - Server-seitige Validierung
- **Rate Limiting** - Cloudflare automatisch
- **HTTPS** - Verschlüsselte Verbindung

## 📜 Changelog

### Version 2.0.0 (2025-11-16) - Interactive Map Release

**Major Features:**
- ✅ Interaktive Leaflet-Karte mit 35 Events
- ✅ Event-Marker mit Custom Icons & Popups
- ✅ Filter-System (Kategorien, Typen, Zeitraum)
- ✅ Echtzeit-Suche über Events
- ✅ Modern Bottom Navigation
- ✅ Side Panel mit Filtern
- ✅ Dark Theme mit Glow-Effekten
- ✅ Responsive Mobile-Design
- ✅ Events-Tabelle mit Geolocation
- ✅ Migrations & Seed-Daten

### Version 1.0.0 (2025-11-16) - Initial Release

- ✅ Dokumenten-Bibliothek
- ✅ Volltext-Suche
- ✅ 20 Dokumente, 17 Kategorien
- ✅ Cloudflare D1 & R2 Integration

## 📞 Support

Bei Fragen oder Problemen:
- **GitHub Issues**: (coming soon)
- **Email**: support@weltenbibliothek.de

---

**⚠️ Hinweis**: Diese Anwendung dient Bildungs- und Forschungszwecken. Die dargestellten Ereignisse und Theorien repräsentieren verschiedene Perspektiven und sollten kritisch betrachtet werden.

**🌍 "Die Wahrheit liegt auf der Karte..."**
