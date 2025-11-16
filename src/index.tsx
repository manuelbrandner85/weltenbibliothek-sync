import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { serveStatic } from 'hono/cloudflare-workers'

type Bindings = {
  DB: D1Database
  MEDIA: R2Bucket
}

const app = new Hono<{ Bindings: Bindings }>()

// Enable CORS for API routes
app.use('/api/*', cors())

// Serve static files
app.use('/static/*', serveStatic({ root: './public' }))

// ===== API Routes =====

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

// Get single document by ID
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

// Upload file to R2 (POST)
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

// Create new document entry
app.post('/api/documents', async (c) => {
  try {
    const body = await c.req.json()
    const { title, author, category, description, file_path } = body

    if (!title || !file_path) {
      return c.json({ error: 'Title and file_path are required' }, 400)
    }

    const result = await c.env.DB.prepare(`
      INSERT INTO documents (title, author, category, description, file_path, created_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    `).bind(title, author || null, category || null, description || null, file_path).run()

    return c.json({ 
      success: true,
      id: result.meta.last_row_id
    })
  } catch (error) {
    console.error('Error creating document:', error)
    return c.json({ error: 'Failed to create document' }, 500)
  }
})

// Get statistics
app.get('/api/stats', async (c) => {
  try {
    const totalDocs = await c.env.DB.prepare(`
      SELECT COUNT(*) as count FROM documents
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
      categories: categoryCounts.results || []
    })
  } catch (error) {
    console.error('Error fetching stats:', error)
    return c.json({ error: 'Failed to fetch statistics' }, 500)
  }
})

// ===== Frontend Route =====
app.get('/', (c) => {
  return c.html(`
    <!DOCTYPE html>
    <html lang="de">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Weltenbibliothek - Die Bibliothek verborgenen Wissens</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0/css/all.min.css" rel="stylesheet">
        <style>
          body {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
          }
          .card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
          }
          .card:hover {
            background: rgba(255, 255, 255, 0.08);
            transform: translateY(-2px);
            transition: all 0.3s ease;
          }
          .glow {
            text-shadow: 0 0 20px rgba(255, 215, 0, 0.5);
          }
          .search-box {
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid rgba(255, 215, 0, 0.3);
          }
          .search-box:focus {
            border-color: rgba(255, 215, 0, 0.6);
            outline: none;
          }
        </style>
    </head>
    <body class="text-gray-100">
        <!-- Header -->
        <div class="container mx-auto px-4 py-8">
            <div class="text-center mb-12">
                <h1 class="text-5xl font-bold mb-4 glow">
                    <i class="fas fa-book-open mr-3"></i>
                    Weltenbibliothek
                </h1>
                <p class="text-xl text-gray-300">
                    Die Bibliothek des verborgenen Wissens, alter Weisheiten und mysteriöser Wahrheiten
                </p>
            </div>

            <!-- Search Section -->
            <div class="max-w-4xl mx-auto mb-12">
                <div class="flex gap-4 mb-6">
                    <input 
                        type="text" 
                        id="searchInput" 
                        placeholder="Durchsuche alte Schriften, Verschwörungstheorien, mystisches Wissen..."
                        class="flex-1 px-6 py-4 rounded-lg search-box text-white placeholder-gray-400"
                    >
                    <button 
                        onclick="search()" 
                        class="px-8 py-4 bg-yellow-600 hover:bg-yellow-700 rounded-lg font-semibold transition-all">
                        <i class="fas fa-search mr-2"></i>
                        Suchen
                    </button>
                </div>
                
                <div class="flex gap-4 flex-wrap" id="categories">
                    <!-- Categories will be loaded here -->
                </div>
            </div>

            <!-- Statistics -->
            <div class="max-w-6xl mx-auto mb-12">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6" id="stats">
                    <!-- Stats will be loaded here -->
                </div>
            </div>

            <!-- Results -->
            <div class="max-w-6xl mx-auto">
                <h2 class="text-2xl font-bold mb-6 flex items-center">
                    <i class="fas fa-scroll mr-3 text-yellow-500"></i>
                    <span id="resultsTitle">Neueste Dokumente</span>
                </h2>
                <div id="results" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <!-- Results will be loaded here -->
                </div>
                
                <div id="loading" class="text-center py-12 hidden">
                    <i class="fas fa-spinner fa-spin text-4xl text-yellow-500"></i>
                    <p class="mt-4 text-gray-300">Durchsuche die Archive...</p>
                </div>
                
                <div id="noResults" class="text-center py-12 hidden">
                    <i class="fas fa-search text-4xl text-gray-500 mb-4"></i>
                    <p class="text-xl text-gray-400">Keine Dokumente gefunden</p>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/axios@1.6.0/dist/axios.min.js"></script>
        <script>
            let currentCategory = '';

            // Load initial data
            loadCategories();
            loadStats();
            search();

            async function loadCategories() {
                try {
                    const response = await axios.get('/api/categories');
                    const categoriesDiv = document.getElementById('categories');
                    
                    const allButton = createCategoryButton('Alle', '', currentCategory === '');
                    categoriesDiv.innerHTML = allButton;
                    
                    response.data.categories.forEach(cat => {
                        const button = createCategoryButton(
                            cat.category, 
                            cat.category, 
                            currentCategory === cat.category
                        );
                        categoriesDiv.innerHTML += button;
                    });
                } catch (error) {
                    console.error('Error loading categories:', error);
                }
            }

            function createCategoryButton(label, value, active) {
                const activeClass = active ? 'bg-yellow-600' : 'bg-gray-700 hover:bg-gray-600';
                return \`<button 
                    onclick="selectCategory('\${value}')" 
                    class="px-4 py-2 \${activeClass} rounded-lg transition-all">
                    <i class="fas fa-tag mr-2"></i>\${label}
                </button>\`;
            }

            function selectCategory(category) {
                currentCategory = category;
                loadCategories();
                search();
            }

            async function loadStats() {
                try {
                    const response = await axios.get('/api/stats');
                    const statsDiv = document.getElementById('stats');
                    
                    statsDiv.innerHTML = \`
                        <div class="card p-6 rounded-lg text-center">
                            <i class="fas fa-book text-4xl text-yellow-500 mb-3"></i>
                            <div class="text-3xl font-bold">\${response.data.total_documents}</div>
                            <div class="text-gray-400 mt-2">Dokumente</div>
                        </div>
                        <div class="card p-6 rounded-lg text-center">
                            <i class="fas fa-tags text-4xl text-purple-500 mb-3"></i>
                            <div class="text-3xl font-bold">\${response.data.categories.length}</div>
                            <div class="text-gray-400 mt-2">Kategorien</div>
                        </div>
                        <div class="card p-6 rounded-lg text-center">
                            <i class="fas fa-eye-slash text-4xl text-red-500 mb-3"></i>
                            <div class="text-3xl font-bold">∞</div>
                            <div class="text-gray-400 mt-2">Geheimnisse</div>
                        </div>
                    \`;
                } catch (error) {
                    console.error('Error loading stats:', error);
                }
            }

            async function search() {
                const query = document.getElementById('searchInput').value;
                const resultsDiv = document.getElementById('results');
                const loadingDiv = document.getElementById('loading');
                const noResultsDiv = document.getElementById('noResults');
                const resultsTitle = document.getElementById('resultsTitle');
                
                resultsDiv.classList.add('hidden');
                noResultsDiv.classList.add('hidden');
                loadingDiv.classList.remove('hidden');

                try {
                    const params = new URLSearchParams();
                    if (query) params.append('q', query);
                    if (currentCategory) params.append('category', currentCategory);
                    
                    const response = await axios.get(\`/api/search?\${params}\`);
                    const documents = response.data.documents;

                    loadingDiv.classList.add('hidden');
                    
                    if (documents.length === 0) {
                        noResultsDiv.classList.remove('hidden');
                        return;
                    }

                    // Update title
                    if (query && currentCategory) {
                        resultsTitle.textContent = \`Ergebnisse für "\${query}" in \${currentCategory}\`;
                    } else if (query) {
                        resultsTitle.textContent = \`Ergebnisse für "\${query}"\`;
                    } else if (currentCategory) {
                        resultsTitle.textContent = \`Dokumente in \${currentCategory}\`;
                    } else {
                        resultsTitle.textContent = 'Neueste Dokumente';
                    }

                    resultsDiv.innerHTML = documents.map(doc => \`
                        <div class="card p-6 rounded-lg cursor-pointer" onclick="viewDocument(\${doc.id})">
                            <div class="flex items-start justify-between mb-4">
                                <div class="flex-1">
                                    <h3 class="text-xl font-bold mb-2 text-yellow-400">\${doc.title}</h3>
                                    \${doc.author ? \`<p class="text-sm text-gray-400 mb-2">
                                        <i class="fas fa-user mr-2"></i>\${doc.author}
                                    </p>\` : ''}
                                </div>
                                <i class="fas fa-file-pdf text-3xl text-red-400"></i>
                            </div>
                            \${doc.category ? \`
                                <span class="inline-block px-3 py-1 bg-purple-600 rounded-full text-xs mb-3">
                                    <i class="fas fa-tag mr-1"></i>\${doc.category}
                                </span>
                            \` : ''}
                            \${doc.description ? \`
                                <p class="text-gray-300 text-sm line-clamp-3">\${doc.description}</p>
                            \` : ''}
                            <div class="mt-4 text-xs text-gray-500">
                                <i class="fas fa-clock mr-1"></i>
                                \${new Date(doc.created_at).toLocaleDateString('de-DE')}
                            </div>
                        </div>
                    \`).join('');
                    
                    resultsDiv.classList.remove('hidden');
                } catch (error) {
                    console.error('Error searching:', error);
                    loadingDiv.classList.add('hidden');
                    noResultsDiv.classList.remove('hidden');
                }
            }

            function viewDocument(id) {
                window.location.href = \`/document/\${id}\`;
            }

            // Search on Enter key
            document.getElementById('searchInput').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') search();
            });
        </script>
    </body>
    </html>
  `)
})

// Document detail page
app.get('/document/:id', async (c) => {
  const id = c.req.param('id')
  
  try {
    const result = await c.env.DB.prepare(`
      SELECT * FROM documents WHERE id = ?
    `).bind(id).first()

    if (!result) {
      return c.html('<h1>Document not found</h1>', 404)
    }

    return c.html(`
      <!DOCTYPE html>
      <html lang="de">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${result.title} - Weltenbibliothek</title>
          <script src="https://cdn.tailwindcss.com"></script>
          <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.4.0/css/all.min.css" rel="stylesheet">
          <style>
            body {
              background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
              min-height: 100vh;
            }
            .card {
              background: rgba(255, 255, 255, 0.05);
              backdrop-filter: blur(10px);
              border: 1px solid rgba(255, 255, 255, 0.1);
            }
            .glow {
              text-shadow: 0 0 20px rgba(255, 215, 0, 0.5);
            }
          </style>
      </head>
      <body class="text-gray-100">
          <div class="container mx-auto px-4 py-8">
              <a href="/" class="inline-block mb-6 text-yellow-500 hover:text-yellow-400">
                  <i class="fas fa-arrow-left mr-2"></i>
                  Zurück zur Bibliothek
              </a>

              <div class="card p-8 rounded-lg max-w-4xl mx-auto">
                  <h1 class="text-4xl font-bold mb-4 glow">${result.title}</h1>
                  
                  ${result.author ? `
                  <p class="text-lg text-gray-300 mb-4">
                      <i class="fas fa-user mr-2"></i>
                      ${result.author}
                  </p>
                  ` : ''}

                  ${result.category ? `
                  <span class="inline-block px-4 py-2 bg-purple-600 rounded-full mb-6">
                      <i class="fas fa-tag mr-2"></i>${result.category}
                  </span>
                  ` : ''}

                  ${result.description ? `
                  <div class="mb-8">
                      <h2 class="text-xl font-bold mb-3">Beschreibung</h2>
                      <p class="text-gray-300 leading-relaxed">${result.description}</p>
                  </div>
                  ` : ''}

                  <div class="mb-6 text-sm text-gray-400">
                      <i class="fas fa-clock mr-2"></i>
                      Hinzugefügt am ${new Date(result.created_at).toLocaleDateString('de-DE', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                  </div>

                  ${result.file_path ? `
                  <div class="mt-8">
                      <a href="/api/files/${result.file_path}" 
                         target="_blank"
                         class="inline-block px-8 py-4 bg-yellow-600 hover:bg-yellow-700 rounded-lg font-semibold transition-all">
                          <i class="fas fa-download mr-2"></i>
                          Dokument öffnen
                      </a>
                  </div>
                  ` : ''}
              </div>
          </div>
      </body>
      </html>
    `)
  } catch (error) {
    console.error('Error loading document:', error)
    return c.html('<h1>Error loading document</h1>', 500)
  }
})

export default app
