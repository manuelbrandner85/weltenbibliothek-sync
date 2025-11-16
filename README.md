# 📚 Weltenbibliothek

**Die Bibliothek des verborgenen Wissens, alter Weisheiten und mysteriöser Wahrheiten**

Eine moderne Web-Anwendung zur Verwaltung und Durchsuchung einer umfangreichen Sammlung von Dokumenten über Verschwörungstheorien, alte Zivilisationen, Mystik und verborgenes Wissen.

## 🌐 Live URLs

- **Sandbox-Entwicklung**: https://3000-i1m8akgt437zr75idt4u6-82b888ba.sandbox.novita.ai
- **Produktion** (nach Deployment): `https://webapp.pages.dev`

## ✨ Features

### ✅ Bereits implementiert

- 🔍 **Volltext-Suche** - Durchsuche Titel, Beschreibung und Autoren
- 🏷️ **Kategorie-Filter** - 17 verschiedene Kategorien
  - Geheimgesellschaften, Alte Zivilisationen, Mystik
  - UFOs, Zeitreisen, Paralleluniversen
  - Außerirdische, Hohle Erde, Kryptozoologie
  - Verschwörungen, Geheimdienste, Alchemie
  - Und viele mehr...
- 📊 **Statistiken** - Übersicht über Dokumentenanzahl und Kategorien
- 📱 **Responsive Design** - Optimiert für Desktop und Mobile
- 🎨 **Dunkles Theme** - Mystisches Design mit Glow-Effekten
- 💾 **Cloudflare D1** - Serverlose SQLite-Datenbank
- 📦 **R2 Storage** - Dokumentenspeicher (PDFs, Bilder)
- ⚡ **Edge Computing** - Blitzschnelle Antwortzeiten weltweit

### 🚀 Geplante Features

- 📤 **Upload-Funktion** - Neue Dokumente hochladen
- 📄 **PDF-Viewer** - Dokumente direkt im Browser anzeigen
- 🔖 **Lesezeichen** - Dokumente für später speichern
- 👤 **Benutzer-Accounts** - Persönliche Sammlungen
- 💬 **Kommentare** - Diskussionen zu Dokumenten
- 🌙 **Theme-Wechsel** - Hell/Dunkel-Modus

## 🗄️ Datenarchitektur

### Cloudflare D1 Datenbank

**Database Name**: `weltenbibliothek_db_v2`  
**Database ID**: `6da1abb7-8ebf-40cb-bc7e-1656b35f2880`

**Schema:**
```sql
documents (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT,
  category TEXT,
  description TEXT,
  file_path TEXT,
  tags TEXT,
  created_at DATETIME,
  updated_at DATETIME
)
```

**Aktueller Bestand**: 20 Dokumente in 17 Kategorien

### Cloudflare R2 Storage

**Bucket Name**: `weltenbibliothek-media`  
**Endpoint**: `https://3472f5994537c3a30c5caeaff4de21fb.r2.cloudflarestorage.com`

**Verwendung:**
- PDF-Dokumente
- Bilder und Icons
- Audio-Dateien (zukünftig)

## 🛠️ Tech Stack

- **Framework**: Hono v4 (Lightweight Web Framework)
- **Runtime**: Cloudflare Workers/Pages
- **Datenbank**: Cloudflare D1 (SQLite)
- **Storage**: Cloudflare R2 (S3-kompatibel)
- **Frontend**: Vanilla JavaScript + Tailwind CSS
- **Build Tool**: Vite
- **Development**: PM2 + Wrangler CLI

## 📋 API Endpoints

### GET `/api/categories`
Gibt alle verfügbaren Kategorien zurück.

**Response:**
```json
{
  "categories": [
    { "category": "Geheimgesellschaften" },
    { "category": "Mystik" },
    ...
  ]
}
```

### GET `/api/search?q=<query>&category=<category>&limit=<limit>&offset=<offset>`
Durchsucht Dokumente mit optionalen Filtern.

**Parameter:**
- `q` - Suchbegriff (optional)
- `category` - Kategorie-Filter (optional)
- `limit` - Anzahl Ergebnisse (default: 20)
- `offset` - Pagination offset (default: 0)

**Response:**
```json
{
  "documents": [
    {
      "id": 1,
      "title": "Die Geheimnisse der Illuminaten",
      "author": "Adam Weishaupt",
      "category": "Geheimgesellschaften",
      "description": "Ein tiefgehender Einblick...",
      "file_path": "documents/illuminati.pdf",
      "created_at": "2025-11-16T12:00:00Z"
    }
  ],
  "query": "illuminati",
  "category": "",
  "limit": 20,
  "offset": 0
}
```

### GET `/api/documents/:id`
Gibt ein einzelnes Dokument zurück.

**Response:**
```json
{
  "document": {
    "id": 1,
    "title": "Die Geheimnisse der Illuminaten",
    ...
  }
}
```

### GET `/api/stats`
Gibt Statistiken über die Bibliothek zurück.

**Response:**
```json
{
  "total_documents": 20,
  "categories": [
    { "category": "Geheimgesellschaften", "count": 2 },
    ...
  ]
}
```

### GET `/api/files/:path`
Lädt eine Datei aus R2 Storage.

**Example:**
```
GET /api/files/documents/illuminati.pdf
```

### POST `/api/upload`
Lädt eine neue Datei hoch (Multipart Form Data).

**Form Data:**
- `file` - Die hochzuladende Datei

**Response:**
```json
{
  "success": true,
  "fileName": "uploads/1234567890-document.pdf",
  "url": "/api/files/uploads/1234567890-document.pdf"
}
```

### POST `/api/documents`
Erstellt einen neuen Dokumenten-Eintrag.

**Body:**
```json
{
  "title": "Neues Dokument",
  "author": "Autor Name",
  "category": "Kategorie",
  "description": "Beschreibung",
  "file_path": "uploads/document.pdf"
}
```

## 🚀 Lokale Entwicklung

### Voraussetzungen
- Node.js 18+
- npm 10+
- PM2 (bereits installiert)

### Setup

```bash
# 1. Dependencies installieren
npm install

# 2. Datenbank-Migrationen anwenden
npm run db:migrate:local

# 3. Testdaten laden
npm run db:seed

# 4. Build durchführen
npm run build

# 5. Development Server starten
pm2 start ecosystem.config.cjs

# 6. Server testen
curl http://localhost:3000
```

### Nützliche Befehle

```bash
# Port 3000 bereinigen
npm run clean-port

# PM2 Status prüfen
pm2 list

# Logs anzeigen (non-blocking)
pm2 logs weltenbibliothek --nostream

# Server neustarten
pm2 restart weltenbibliothek

# Server stoppen
pm2 stop weltenbibliothek

# Datenbank-Konsole (lokal)
npm run db:console:local

# Datenbank-Konsole (Produktion)
npm run db:console:prod

# Git Status
npm run git:status
```

## 📦 Deployment auf Cloudflare Pages

### 1. Cloudflare API einrichten

```bash
# Setup Cloudflare API Key
# Folge den Anweisungen im Deploy-Tab
```

### 2. Migrationen auf Produktion anwenden

```bash
# Datenbank-Migrationen
npx wrangler d1 migrations apply weltenbibliothek_db_v2

# Testdaten laden (optional)
npx wrangler d1 execute weltenbibliothek_db_v2 --file=./seed.sql
```

### 3. Deployment durchführen

```bash
# Build und Deploy
npm run deploy:prod

# Oder manuell
npm run build
npx wrangler pages deploy dist --project-name webapp
```

### 4. URLs nach Deployment

- Production: `https://webapp.pages.dev`
- Branch: `https://main.webapp.pages.dev`

## 🗂️ Projektstruktur

```
webapp/
├── src/
│   ├── index.tsx          # Haupt-Hono-App mit allen Routes
│   └── renderer.tsx       # JSX Renderer (falls benötigt)
├── public/
│   └── static/            # Statische Assets
├── migrations/
│   └── 0001_create_documents.sql  # DB Schema
├── dist/                  # Build Output (generiert)
├── .wrangler/            # Lokale D1 Datenbank (generiert)
├── ecosystem.config.cjs   # PM2 Konfiguration
├── wrangler.jsonc        # Cloudflare Workers Config
├── package.json          # Dependencies & Scripts
├── vite.config.ts        # Vite Build Config
├── seed.sql              # Testdaten
└── README.md             # Diese Datei
```

## 🎨 Design-Philosophie

Die Weltenbibliothek verwendet ein **mystisches, dunkles Design**, das die Atmosphäre verborgenen Wissens vermittelt:

- **Farbschema**: Dunkle Blautöne (#1a1a2e, #16213e) mit goldenen Akzenten
- **Effekte**: Glow-Effekte für Überschriften, Glassmorphismus für Karten
- **Icons**: FontAwesome für konsistente Symbolik
- **Responsive**: Mobile-First Approach mit Tailwind CSS

## 📊 Datenbank-Kategorien

Die Bibliothek organisiert Dokumente in folgende Kategorien:

1. **Geheimgesellschaften** - Illuminaten, Freimaurer, Skull & Bones
2. **Alte Zivilisationen** - Atlantis, Lemuria, Mu
3. **Mystik** - Drittes Auge, Chakren, Meditation
4. **Alte Astronauten** - Anunnaki, Götter-Astronauten
5. **Archäologie** - Verborgene Kammern, Artefakte
6. **Verschwörungen** - NWO, Deep State, False Flags
7. **Esoterik** - Frequenzen, Kristalle, Energien
8. **Hohle Erde** - Agartha, innere Welten
9. **Geheimdienste** - MK-Ultra, CIA-Programme
10. **Zeitreisen** - Philadelphia-Experiment, Montauk
11. **Klimamanipulation** - Chemtrails, HAARP, Geoengineering
12. **Alchemie** - Transmutation, Smaragdtafeln
13. **Außerirdische** - Reptiloiden, Graue, Nordics
14. **UFOs** - Area 51, Roswell, Begegnungen
15. **Unterdrückte Technologie** - Freie Energie, Tesla
16. **Kryptozoologie** - Bigfoot, Nessie, Chupacabra
17. **Paralleluniversen** - Mandela-Effekt, Zeitlinien

## 🔐 Sicherheit

- **API Keys**: Niemals im Code committen
- **Environment Variables**: Nutzung von `.dev.vars` (lokal) und Cloudflare Secrets (Produktion)
- **Input Validation**: SQL Injection Schutz durch Prepared Statements
- **CORS**: Konfiguriert für API-Routes
- **Rate Limiting**: Über Cloudflare automatisch

## 🤝 Beitragen

Neue Dokumente können über die API hinzugefügt werden:

```bash
# 1. Datei hochladen
curl -X POST -F "file=@dokument.pdf" http://localhost:3000/api/upload

# 2. Dokumenten-Eintrag erstellen
curl -X POST http://localhost:3000/api/documents \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Neues mystisches Wissen",
    "author": "Unbekannt",
    "category": "Mystik",
    "description": "Beschreibung...",
    "file_path": "uploads/1234567890-dokument.pdf"
  }'
```

## 📝 Changelog

### Version 1.0.0 (2025-11-16)

**Initial Release:**
- ✅ Hono Backend mit Cloudflare Workers
- ✅ D1 SQLite Datenbank Integration
- ✅ R2 Object Storage für Dateien
- ✅ Volltext-Suche über 20 Dokumente
- ✅ 17 Kategorien mit Filter-Funktion
- ✅ Responsive Frontend mit Tailwind CSS
- ✅ API mit 8 Endpoints
- ✅ PM2 Development Environment
- ✅ Migrations & Seed Data

## 📞 Kontakt & Support

Bei Fragen oder Problemen:

- **GitHub Issues**: (noch nicht verfügbar)
- **Email**: manuel.brandner@example.com

## 📜 Lizenz

Dieses Projekt ist für **Bildungs- und Forschungszwecke** erstellt worden.

---

**⚠️ Hinweis**: Die in dieser Bibliothek gesammelten Dokumente dienen ausschließlich der Information und Aufklärung über Verschwörungstheorien und alternative Sichtweisen. Sie stellen nicht notwendigerweise die Meinung der Entwickler dar.

**🔮 "Die Wahrheit ist irgendwo da draußen..."**
