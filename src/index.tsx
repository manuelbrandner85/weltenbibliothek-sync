import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { serveStatic } from 'hono/cloudflare-workers'

type Bindings = {
  DB: D1Database
  MEDIA: R2Bucket
}

const app = new Hono<{ Bindings: Bindings }>()

// Enable CORS
app.use('/api/*', cors())

// Serve static files
app.use('/static/*', serveStatic({ root: './public' }))

// ===== Map & Events API =====

// Get all events for map
app.get('/api/events', async (c) => {
  try {
    const category = c.req.query('category') || ''
    const type = c.req.query('type') || ''
    const year_from = c.req.query('year_from') || ''
    const year_to = c.req.query('year_to') || ''

    let sql = `
      SELECT id, title, description, latitude, longitude, category, 
             event_type, year, date_text, icon_type, image_url, related_document_id
      FROM events 
      WHERE 1=1
    `
    const params: any[] = []

    if (category) {
      sql += ` AND category = ?`
      params.push(category)
    }

    if (type) {
      sql += ` AND event_type = ?`
      params.push(type)
    }

    if (year_from) {
      sql += ` AND year >= ?`
      params.push(parseInt(year_from))
    }

    if (year_to) {
      sql += ` AND year <= ?`
      params.push(parseInt(year_to))
    }

    sql += ` ORDER BY created_at DESC`

    const result = await c.env.DB.prepare(sql).bind(...params).all()
    
    return c.json({ 
      success: true,
      events: result.results || []
    })
  } catch (error) {
    console.error('Error fetching events:', error)
    return c.json({ success: false, error: 'Failed to fetch events', events: [] }, 500)
  }
})

// Get single event
app.get('/api/events/:id', async (c) => {
  const id = c.req.param('id')
  
  try {
    const result = await c.env.DB.prepare(`
      SELECT e.*, d.title as document_title, d.file_path as document_path
      FROM events e
      LEFT JOIN documents d ON e.related_document_id = d.id
      WHERE e.id = ?
    `).bind(id).first()

    if (!result) {
      return c.json({ success: false, error: 'Event not found' }, 404)
    }

    return c.json({ success: true, event: result })
  } catch (error) {
    console.error('Error fetching event:', error)
    return c.json({ success: false, error: 'Failed to fetch event' }, 500)
  }
})

// Get event categories
app.get('/api/events/categories', async (c) => {
  try {
    const result = await c.env.DB.prepare(`
      SELECT DISTINCT category, COUNT(*) as count
      FROM events 
      WHERE category IS NOT NULL 
      GROUP BY category 
      ORDER BY count DESC
    `).all()
    
    return c.json({ success: true, categories: result.results || [] })
  } catch (error) {
    console.error('Error fetching categories:', error)
    return c.json({ success: false, categories: [] }, 500)
  }
})

// Get event types
app.get('/api/events/types', async (c) => {
  try {
    const result = await c.env.DB.prepare(`
      SELECT DISTINCT event_type, COUNT(*) as count
      FROM events 
      WHERE event_type IS NOT NULL 
      GROUP BY event_type 
      ORDER BY count DESC
    `).all()
    
    return c.json({ success: true, types: result.results || [] })
  } catch (error) {
    console.error('Error fetching types:', error)
    return c.json({ success: false, types: [] }, 500)
  }
})

// ===== Documents API =====

// Get all categories
app.get('/api/categories', async (c) => {
  try {
    const result = await c.env.DB.prepare(`
      SELECT DISTINCT category 
      FROM documents 
      WHERE category IS NOT NULL 
      ORDER BY category
    `).all()
    
    return c.json({ categories: result.results || [] })
  } catch (error) {
    console.error('Error fetching categories:', error)
    return c.json({ error: 'Failed to fetch categories', categories: [] }, 500)
  }
})

// Search documents
app.get('/api/search', async (c) => {
  const query = c.req.query('q') || ''
  const category = c.req.query('category') || ''
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  try {
    let sql = `
      SELECT id, title, author, category, description, file_path, created_at 
      FROM documents 
      WHERE 1=1
    `
    const params: string[] = []

    if (query) {
      sql += ` AND (title LIKE ? OR description LIKE ? OR author LIKE ?)`
      const searchTerm = `%${query}%`
      params.push(searchTerm, searchTerm, searchTerm)
    }

    if (category) {
      sql += ` AND category = ?`
      params.push(category)
    }

    sql += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`
    params.push(limit.toString(), offset.toString())

    const result = await c.env.DB.prepare(sql).bind(...params).all()
    
    return c.json({ 
      documents: result.results || [],
      query,
      category,
      limit,
      offset
    })
  } catch (error) {
    console.error('Error searching documents:', error)
    return c.json({ error: 'Search failed', documents: [] }, 500)
  }
})

// Get single document
app.get('/api/documents/:id', async (c) => {
  const id = c.req.param('id')
  
  try {
    const result = await c.env.DB.prepare(`
      SELECT * FROM documents WHERE id = ?
    `).bind(id).first()

    if (!result) {
      return c.json({ error: 'Document not found' }, 404)
    }

    return c.json({ document: result })
  } catch (error) {
    console.error('Error fetching document:', error)
    return c.json({ error: 'Failed to fetch document' }, 500)
  }
})

// Get statistics
app.get('/api/stats', async (c) => {
  try {
    const totalDocs = await c.env.DB.prepare(`
      SELECT COUNT(*) as count FROM documents
    `).first()

    const totalEvents = await c.env.DB.prepare(`
      SELECT COUNT(*) as count FROM events
    `).first()

    const categoryCounts = await c.env.DB.prepare(`
      SELECT category, COUNT(*) as count 
      FROM documents 
      WHERE category IS NOT NULL 
      GROUP BY category 
      ORDER BY count DESC
    `).all()

    return c.json({
      total_documents: totalDocs?.count || 0,
      total_events: totalEvents?.count || 0,
      categories: categoryCounts.results || []
    })
  } catch (error) {
    console.error('Error fetching stats:', error)
    return c.json({ error: 'Failed to fetch statistics' }, 500)
  }
})

// ===== File Management =====

// Get file from R2
app.get('/api/files/:path{.+}', async (c) => {
  const path = c.req.param('path')
  
  try {
    const object = await c.env.MEDIA.get(path)
    
    if (!object) {
      return c.notFound()
    }

    const headers = new Headers()
    object.writeHttpMetadata(headers)
    headers.set('etag', object.httpEtag)
    headers.set('Cache-Control', 'public, max-age=31536000')

    return new Response(object.body, { headers })
  } catch (error) {
    console.error('Error fetching file:', error)
    return c.json({ error: 'File not found' }, 404)
  }
})

// Upload file to R2
app.post('/api/upload', async (c) => {
  try {
    const formData = await c.req.formData()
    const file = formData.get('file') as File
    
    if (!file) {
      return c.json({ error: 'No file provided' }, 400)
    }

    const fileName = `uploads/${Date.now()}-${file.name}`
    const arrayBuffer = await file.arrayBuffer()
    
    await c.env.MEDIA.put(fileName, arrayBuffer, {
      httpMetadata: {
        contentType: file.type
      }
    })

    return c.json({ 
      success: true, 
      fileName,
      url: `/api/files/${fileName}`
    })
  } catch (error) {
    console.error('Error uploading file:', error)
    return c.json({ error: 'Upload failed' }, 500)
  }
})

// ===== Frontend Routes =====

// Main Map View
app.get('/', (c) => {
  return c.html(`
    <!DOCTYPE html>
    <html lang="de">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Weltenbibliothek - Interaktive Karte</title>
        
        <!-- Leaflet CSS -->
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        
        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>
        
        <!-- FontAwesome -->
        <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0/css/all.min.css" rel="stylesheet">
        
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #1a1a2e;
            color: #fff;
            overflow: hidden;
          }
          
          #map {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 1;
          }
          
          /* Custom marker clusters */
          .marker-cluster {
            background: rgba(255, 215, 0, 0.6);
            border-radius: 50%;
            text-align: center;
            color: #fff;
            font-weight: bold;
          }
          
          .marker-cluster div {
            background: rgba(255, 215, 0, 0.8);
            border-radius: 50%;
            width: 30px;
            height: 30px;
            margin: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          
          /* Custom markers */
          .custom-marker {
            background: none;
            border: none;
          }
          
          .custom-marker i {
            font-size: 24px;
            text-shadow: 0 0 10px rgba(0,0,0,0.5);
          }
          
          /* Top bar */
          #top-bar {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            height: 60px;
            background: rgba(26, 26, 46, 0.95);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid rgba(255, 215, 0, 0.3);
            z-index: 1000;
            display: flex;
            align-items: center;
            padding: 0 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.5);
          }
          
          #logo {
            display: flex;
            align-items: center;
            font-size: 20px;
            font-weight: bold;
            color: #ffd700;
            text-shadow: 0 0 20px rgba(255, 215, 0, 0.5);
          }
          
          #logo img {
            width: 40px;
            height: 40px;
            margin-right: 10px;
            border-radius: 8px;
          }
          
          #search-container {
            flex: 1;
            max-width: 600px;
            margin: 0 20px;
          }
          
          #search-input {
            width: 100%;
            padding: 10px 40px 10px 15px;
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid rgba(255, 215, 0, 0.3);
            border-radius: 25px;
            color: #fff;
            font-size: 14px;
            outline: none;
            transition: all 0.3s;
          }
          
          #search-input:focus {
            border-color: rgba(255, 215, 0, 0.6);
            background: rgba(255, 255, 255, 0.15);
          }
          
          #search-input::placeholder {
            color: rgba(255, 255, 255, 0.5);
          }
          
          /* Bottom Navigation */
          #bottom-nav {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            height: 70px;
            background: rgba(26, 26, 46, 0.95);
            backdrop-filter: blur(10px);
            border-top: 1px solid rgba(255, 215, 0, 0.3);
            z-index: 1000;
            display: flex;
            justify-content: space-around;
            align-items: center;
            padding: 0 20px;
            box-shadow: 0 -2px 10px rgba(0,0,0,0.5);
          }
          
          .nav-item {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s;
            padding: 10px;
            border-radius: 10px;
          }
          
          .nav-item:hover {
            background: rgba(255, 215, 0, 0.1);
          }
          
          .nav-item.active {
            background: rgba(255, 215, 0, 0.2);
          }
          
          .nav-item i {
            font-size: 24px;
            margin-bottom: 5px;
            color: rgba(255, 255, 255, 0.7);
          }
          
          .nav-item.active i {
            color: #ffd700;
          }
          
          .nav-item span {
            font-size: 12px;
            color: rgba(255, 255, 255, 0.7);
          }
          
          .nav-item.active span {
            color: #ffd700;
          }
          
          /* Side panel */
          #side-panel {
            position: fixed;
            right: -400px;
            top: 60px;
            bottom: 70px;
            width: 400px;
            background: rgba(26, 26, 46, 0.98);
            backdrop-filter: blur(20px);
            border-left: 1px solid rgba(255, 215, 0, 0.3);
            z-index: 900;
            transition: right 0.3s ease;
            overflow-y: auto;
            padding: 20px;
          }
          
          #side-panel.open {
            right: 0;
          }
          
          #side-panel::-webkit-scrollbar {
            width: 8px;
          }
          
          #side-panel::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.05);
          }
          
          #side-panel::-webkit-scrollbar-thumb {
            background: rgba(255, 215, 0, 0.3);
            border-radius: 4px;
          }
          
          /* Filter panel */
          .filter-section {
            margin-bottom: 20px;
          }
          
          .filter-section h3 {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #ffd700;
          }
          
          .filter-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
          }
          
          .filter-chip {
            padding: 6px 12px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 215, 0, 0.3);
            border-radius: 15px;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.3s;
          }
          
          .filter-chip:hover {
            background: rgba(255, 215, 0, 0.2);
          }
          
          .filter-chip.active {
            background: rgba(255, 215, 0, 0.3);
            border-color: #ffd700;
          }
          
          /* Popup custom styles */
          .leaflet-popup-content-wrapper {
            background: rgba(26, 26, 46, 0.98);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 215, 0, 0.3);
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
          }
          
          .leaflet-popup-content {
            margin: 15px;
            color: #fff;
            min-width: 250px;
          }
          
          .leaflet-popup-tip {
            background: rgba(26, 26, 46, 0.98);
          }
          
          .popup-title {
            font-size: 18px;
            font-weight: bold;
            color: #ffd700;
            margin-bottom: 10px;
          }
          
          .popup-meta {
            display: flex;
            gap: 10px;
            margin-bottom: 10px;
            font-size: 12px;
            color: rgba(255, 255, 255, 0.7);
          }
          
          .popup-description {
            font-size: 14px;
            line-height: 1.6;
            margin-bottom: 15px;
          }
          
          .popup-button {
            display: inline-block;
            padding: 8px 16px;
            background: rgba(255, 215, 0, 0.2);
            border: 1px solid #ffd700;
            border-radius: 5px;
            color: #ffd700;
            text-decoration: none;
            font-size: 14px;
            transition: all 0.3s;
          }
          
          .popup-button:hover {
            background: rgba(255, 215, 0, 0.3);
          }
          
          /* Loading spinner */
          .spinner {
            border: 3px solid rgba(255, 255, 255, 0.1);
            border-top: 3px solid #ffd700;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
          }
          
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          
          /* Mobile responsive */
          @media (max-width: 768px) {
            #side-panel {
              width: 100%;
              right: -100%;
            }
            
            #search-container {
              margin: 0 10px;
            }
            
            #top-bar {
              padding: 0 10px;
            }
          }
        </style>
    </head>
    <body>
        <!-- Top Bar -->
        <div id="top-bar">
            <div id="logo">
                <img src="/static/app_icon.png" alt="Weltenbibliothek" />
                <span>Weltenbibliothek</span>
            </div>
            <div id="search-container">
                <input type="text" id="search-input" placeholder="Suche nach Ereignissen, Orten, Verschwörungen..." />
            </div>
            <button onclick="toggleFilters()" class="px-4 py-2 bg-yellow-600 hover:bg-yellow-700 rounded-lg transition">
                <i class="fas fa-filter mr-2"></i>
                Filter
            </button>
        </div>

        <!-- Map Container -->
        <div id="map"></div>

        <!-- Side Panel (Filters) -->
        <div id="side-panel">
            <h2 class="text-2xl font-bold mb-6 text-yellow-400">
                <i class="fas fa-sliders-h mr-2"></i>
                Filter & Kategorien
            </h2>
            
            <div class="filter-section">
                <h3>Kategorien</h3>
                <div id="categories-filter" class="filter-chips">
                    <div class="spinner"></div>
                </div>
            </div>
            
            <div class="filter-section">
                <h3>Event-Typen</h3>
                <div id="types-filter" class="filter-chips">
                    <div class="spinner"></div>
                </div>
            </div>
            
            <div class="filter-section">
                <h3>Zeitraum</h3>
                <div class="flex gap-4">
                    <input type="number" id="year-from" placeholder="Von Jahr" class="flex-1 px-3 py-2 bg-gray-800 border border-gray-700 rounded" />
                    <input type="number" id="year-to" placeholder="Bis Jahr" class="flex-1 px-3 py-2 bg-gray-800 border border-gray-700 rounded" />
                </div>
                <button onclick="applyFilters()" class="mt-3 w-full px-4 py-2 bg-yellow-600 hover:bg-yellow-700 rounded-lg transition">
                    Anwenden
                </button>
            </div>
            
            <div class="filter-section">
                <button onclick="clearFilters()" class="w-full px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition">
                    Filter zurücksetzen
                </button>
            </div>
        </div>

        <!-- Bottom Navigation -->
        <div id="bottom-nav">
            <div class="nav-item active" onclick="switchTab('map')">
                <i class="fas fa-map-marked-alt"></i>
                <span>Karte</span>
            </div>
            <div class="nav-item" onclick="switchTab('list')">
                <i class="fas fa-list"></i>
                <span>Liste</span>
            </div>
            <div class="nav-item" onclick="switchTab('documents')">
                <i class="fas fa-book"></i>
                <span>Dokumente</span>
            </div>
            <div class="nav-item" onclick="switchTab('timeline')">
                <i class="fas fa-clock"></i>
                <span>Timeline</span>
            </div>
        </div>

        <!-- Leaflet JS -->
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        
        <!-- Axios -->
        <script src="https://cdn.jsdelivr.net/npm/axios@1.6.0/dist/axios.min.js"></script>
        
        <script src="/static/app.js"></script>
    </body>
    </html>
  `)
})

// List View
app.get('/list', (c) => {
  return c.html('<h1>List View - Coming Soon</h1>')
})

// Documents View
app.get('/documents', (c) => {
  return c.html('<h1>Documents View - Coming Soon</h1>')
})

// Timeline View
app.get('/timeline', (c) => {
  return c.html('<h1>Timeline View - Coming Soon</h1>')
})

export default app
