import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { serveStatic } from 'hono/cloudflare-workers'
import { hashPassword, verifyPassword, generateToken, verifyToken, authMiddleware, optionalAuthMiddleware } from './auth'

type Bindings = {
  DB: D1Database
}

const app = new Hono<{ Bindings: Bindings }>()

// Enable CORS
app.use('/api/*', cors())

// Serve static files
app.use('/static/*', serveStatic({ root: './public' }))

// ===== Authentication API =====

// Register new user (simplified: only username + password)
app.post('/api/auth/register', async (c) => {
  try {
    const { username, password } = await c.req.json()
    
    // Validation
    if (!username || !password) {
      return c.json({ success: false, error: 'Benutzername und Passwort sind erforderlich' }, 400)
    }
    
    if (password.length < 6) {
      return c.json({ success: false, error: 'Passwort muss mindestens 6 Zeichen haben' }, 400)
    }
    
    if (username.length < 3) {
      return c.json({ success: false, error: 'Benutzername muss mindestens 3 Zeichen haben' }, 400)
    }
    
    // Check if username already exists
    const existing = await c.env.DB.prepare(`
      SELECT id FROM users WHERE username = ?
    `).bind(username).first()
    
    if (existing) {
      return c.json({ success: false, error: 'Dieser Benutzername ist bereits vergeben' }, 409)
    }
    
    // Hash password
    const passwordHash = await hashPassword(password)
    
    // Create user (email is optional now, display_name = username)
    const result = await c.env.DB.prepare(`
      INSERT INTO users (username, email, password_hash, display_name, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    `).bind(username, `${username}@weltenbibliothek.local`, passwordHash, username).run()
    
    if (!result.success) {
      return c.json({ success: false, error: 'Registrierung fehlgeschlagen' }, 500)
    }
    
    // Get the created user
    const user = await c.env.DB.prepare(`
      SELECT id, username, display_name, is_admin, created_at
      FROM users WHERE username = ?
    `).bind(username).first()
    
    // Generate token
    const token = await generateToken(user.id as number, user.username as string)
    
    return c.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        display_name: user.display_name,
        is_admin: user.is_admin,
        created_at: user.created_at
      },
      token
    })
  } catch (error) {
    console.error('Register error:', error)
    return c.json({ success: false, error: 'Registrierung fehlgeschlagen' }, 500)
  }
})

// Login
app.post('/api/auth/login', async (c) => {
  try {
    const { username, password } = await c.req.json()
    
    if (!username || !password) {
      return c.json({ success: false, error: 'Username and password are required' }, 400)
    }
    
    // Find user
    const user = await c.env.DB.prepare(`
      SELECT id, username, email, password_hash, display_name, avatar_url, bio, is_admin, created_at
      FROM users WHERE username = ?
    `).bind(username).first()
    
    if (!user) {
      return c.json({ success: false, error: 'Invalid credentials' }, 401)
    }
    
    // Verify password
    const validPassword = await verifyPassword(password, user.password_hash as string)
    
    if (!validPassword) {
      return c.json({ success: false, error: 'Invalid credentials' }, 401)
    }
    
    // Update last_seen
    await c.env.DB.prepare(`
      UPDATE users SET last_seen = datetime('now'), status = 'online' WHERE id = ?
    `).bind(user.id).run()
    
    // Generate token
    const token = await generateToken(user.id as number, user.username as string)
    
    return c.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        display_name: user.display_name,
        avatar_url: user.avatar_url,
        bio: user.bio,
        is_admin: user.is_admin,
        created_at: user.created_at
      },
      token
    })
  } catch (error) {
    console.error('Login error:', error)
    return c.json({ success: false, error: 'Login failed' }, 500)
  }
})

// Get current user profile (protected)
app.get('/api/auth/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    
    const user = await c.env.DB.prepare(`
      SELECT id, username, email, display_name, avatar_url, bio, interests, is_verified, created_at, last_seen
      FROM users WHERE id = ?
    `).bind(userId).first()
    
    if (!user) {
      return c.json({ success: false, error: 'User not found' }, 404)
    }
    
    return c.json({ success: true, user })
  } catch (error) {
    console.error('Get profile error:', error)
    return c.json({ success: false, error: 'Failed to fetch profile' }, 500)
  }
})

// Update user profile (protected)
app.put('/api/auth/profile', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const { display_name, bio, interests, avatar_url } = await c.req.json()
    
    await c.env.DB.prepare(`
      UPDATE users 
      SET display_name = COALESCE(?, display_name),
          bio = COALESCE(?, bio),
          interests = COALESCE(?, interests),
          avatar_url = COALESCE(?, avatar_url),
          updated_at = datetime('now')
      WHERE id = ?
    `).bind(display_name, bio, interests, avatar_url, userId).run()
    
    return c.json({ success: true, message: 'Profile updated' })
  } catch (error) {
    console.error('Update profile error:', error)
    return c.json({ success: false, error: 'Failed to update profile' }, 500)
  }
})

// Logout (update status)
app.post('/api/auth/logout', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    
    await c.env.DB.prepare(`
      UPDATE users SET status = 'offline', last_seen = datetime('now') WHERE id = ?
    `).bind(userId).run()
    
    return c.json({ success: true, message: 'Logged out successfully' })
  } catch (error) {
    console.error('Logout error:', error)
    return c.json({ success: false, error: 'Logout failed' }, 500)
  }
})

// ===== Notifications API =====

// Get user notifications (protected)
app.get('/api/notifications', authMiddleware, async (c) => {
  const userId = c.get('userId')
  const limit = parseInt(c.req.query('limit') || '50')
  const unreadOnly = c.req.query('unread_only') === 'true'
  
  try {
    let query = `
      SELECT * FROM notifications 
      WHERE user_id = ?
    `
    if (unreadOnly) {
      query += ` AND is_read = 0`
    }
    query += ` ORDER BY created_at DESC LIMIT ?`
    
    const result = await c.env.DB.prepare(query).bind(userId, limit).all()
    
    return c.json({ 
      success: true, 
      notifications: result.results || [],
      unread_count: result.results?.filter((n: any) => !n.is_read).length || 0
    })
  } catch (error) {
    console.error('Error fetching notifications:', error)
    return c.json({ success: false, error: 'Failed to fetch notifications' }, 500)
  }
})

// Mark notification as read (protected)
app.put('/api/notifications/:id/read', authMiddleware, async (c) => {
  const notificationId = c.req.param('id')
  const userId = c.get('userId')
  
  try {
    await c.env.DB.prepare(`
      UPDATE notifications 
      SET is_read = 1, read_at = datetime('now')
      WHERE id = ? AND user_id = ?
    `).bind(notificationId, userId).run()
    
    return c.json({ success: true })
  } catch (error) {
    console.error('Error marking notification as read:', error)
    return c.json({ success: false }, 500)
  }
})

// Mark all notifications as read (protected)
app.put('/api/notifications/read-all', authMiddleware, async (c) => {
  const userId = c.get('userId')
  
  try {
    await c.env.DB.prepare(`
      UPDATE notifications 
      SET is_read = 1, read_at = datetime('now')
      WHERE user_id = ? AND is_read = 0
    `).bind(userId).run()
    
    return c.json({ success: true })
  } catch (error) {
    console.error('Error marking all as read:', error)
    return c.json({ success: false }, 500)
  }
})

// Create notification (internal helper - called when events happen)
async function createNotification(
  db: D1Database,
  userId: number,
  type: string,
  title: string,
  body: string,
  data?: any
) {
  try {
    await db.prepare(`
      INSERT INTO notifications (user_id, notification_type, title, body, data, created_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    `).bind(userId, type, title, body, JSON.stringify(data || {})).run()
  } catch (error) {
    console.error('Error creating notification:', error)
  }
}

// ===== Admin API =====

// Middleware for admin-only routes
async function adminMiddleware(c: any, next: Function) {
  await authMiddleware(c, async () => {
    const userId = c.get('userId')
    
    const user = await c.env.DB.prepare(`
      SELECT role, is_admin FROM users WHERE id = ?
    `).bind(userId).first()
    
    if (!user || (user.role !== 'superadmin' && user.role !== 'admin' && user.role !== 'moderator')) {
      return c.json({ success: false, error: 'Zugriff verweigert' }, 403)
    }
    
    c.set('userRole', user.role)
    await next()
  })
}

// Get all users (admin only)
app.get('/api/admin/users', adminMiddleware, async (c) => {
  try {
    const result = await c.env.DB.prepare(`
      SELECT id, username, display_name, role, is_admin, is_verified, status, created_at, last_seen
      FROM users
      ORDER BY created_at DESC
    `).all()
    
    return c.json({ success: true, users: result.results || [] })
  } catch (error) {
    console.error('Error fetching users:', error)
    return c.json({ success: false, error: 'Failed to fetch users' }, 500)
  }
})

// Update user role (superadmin only)
app.put('/api/admin/users/:id/role', adminMiddleware, async (c) => {
  try {
    const userRole = c.get('userRole')
    
    if (userRole !== 'superadmin') {
      return c.json({ success: false, error: 'Nur Super Admin kann Rollen ändern' }, 403)
    }
    
    const userId = c.req.param('id')
    const { role } = await c.req.json()
    
    if (!['user', 'moderator', 'admin'].includes(role)) {
      return c.json({ success: false, error: 'Ungültige Rolle' }, 400)
    }
    
    // Cannot change superadmin role
    const targetUser = await c.env.DB.prepare(`
      SELECT role FROM users WHERE id = ?
    `).bind(userId).first()
    
    if (targetUser?.role === 'superadmin') {
      return c.json({ success: false, error: 'Super Admin Rolle kann nicht geändert werden' }, 403)
    }
    
    await c.env.DB.prepare(`
      UPDATE users SET role = ?, is_admin = ?, updated_at = datetime('now')
      WHERE id = ?
    `).bind(role, role !== 'user' ? 1 : 0, userId).run()
    
    return c.json({ success: true, message: 'Rolle aktualisiert' })
  } catch (error) {
    console.error('Error updating role:', error)
    return c.json({ success: false, error: 'Failed to update role' }, 500)
  }
})

// Ban/Unban user (admin only)
app.put('/api/admin/users/:id/ban', adminMiddleware, async (c) => {
  try {
    const userRole = c.get('userRole')
    const userId = c.req.param('id')
    const { banned } = await c.req.json()
    
    // Moderators can't ban admins
    const targetUser = await c.env.DB.prepare(`
      SELECT role FROM users WHERE id = ?
    `).bind(userId).first()
    
    if (targetUser?.role === 'superadmin') {
      return c.json({ success: false, error: 'Super Admin kann nicht gebannt werden' }, 403)
    }
    
    if (userRole === 'moderator' && (targetUser?.role === 'admin' || targetUser?.role === 'moderator')) {
      return c.json({ success: false, error: 'Moderatoren können keine Admins/Moderatoren bannen' }, 403)
    }
    
    await c.env.DB.prepare(`
      UPDATE users SET status = ?, updated_at = datetime('now')
      WHERE id = ?
    `).bind(banned ? 'banned' : 'offline', userId).run()
    
    return c.json({ success: true, message: banned ? 'User gebannt' : 'Ban aufgehoben' })
  } catch (error) {
    console.error('Error banning user:', error)
    return c.json({ success: false, error: 'Failed to ban user' }, 500)
  }
})

// Delete user (superadmin only)
app.delete('/api/admin/users/:id', adminMiddleware, async (c) => {
  try {
    const userRole = c.get('userRole')
    
    if (userRole !== 'superadmin') {
      return c.json({ success: false, error: 'Nur Super Admin kann User löschen' }, 403)
    }
    
    const userId = c.req.param('id')
    
    // Cannot delete superadmin
    const targetUser = await c.env.DB.prepare(`
      SELECT role FROM users WHERE id = ?
    `).bind(userId).first()
    
    if (targetUser?.role === 'superadmin') {
      return c.json({ success: false, error: 'Super Admin kann nicht gelöscht werden' }, 403)
    }
    
    await c.env.DB.prepare(`DELETE FROM users WHERE id = ?`).bind(userId).run()
    
    return c.json({ success: true, message: 'User gelöscht' })
  } catch (error) {
    console.error('Error deleting user:', error)
    return c.json({ success: false, error: 'Failed to delete user' }, 500)
  }
})

// Get admin stats (admin only)
app.get('/api/admin/stats', adminMiddleware, async (c) => {
  try {
    const userCount = await c.env.DB.prepare(`SELECT COUNT(*) as count FROM users`).first()
    const chatCount = await c.env.DB.prepare(`SELECT COUNT(*) as count FROM chats`).first()
    const messageCount = await c.env.DB.prepare(`SELECT COUNT(*) as count FROM messages`).first()
    const eventCount = await c.env.DB.prepare(`SELECT COUNT(*) as count FROM events`).first()
    
    return c.json({
      success: true,
      stats: {
        users: userCount?.count || 0,
        chats: chatCount?.count || 0,
        messages: messageCount?.count || 0,
        events: eventCount?.count || 0
      }
    })
  } catch (error) {
    console.error('Error fetching stats:', error)
    return c.json({ success: false, error: 'Failed to fetch stats' }, 500)
  }
})

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

// Update event view count (optional auth)
app.put('/api/events/:id/view', optionalAuthMiddleware, async (c) => {
  const eventId = c.req.param('id')
  
  try {
    await c.env.DB.prepare(`
      UPDATE events 
      SET view_count = view_count + 1 
      WHERE id = ?
    `).bind(eventId).run()
    
    return c.json({ success: true })
  } catch (error) {
    console.error('Error updating view count:', error)
    return c.json({ success: false }, 500)
  }
})

// Bookmark event (protected)
app.post('/api/events/:id/bookmark', authMiddleware, async (c) => {
  const eventId = c.req.param('id')
  const userId = c.get('userId')
  
  try {
    // Check if already bookmarked
    const existing = await c.env.DB.prepare(`
      SELECT id FROM event_bookmarks WHERE event_id = ? AND user_id = ?
    `).bind(eventId, userId).first()
    
    if (existing) {
      return c.json({ success: true, message: 'Already bookmarked' })
    }
    
    // Add bookmark
    await c.env.DB.prepare(`
      INSERT INTO event_bookmarks (event_id, user_id, created_at)
      VALUES (?, ?, datetime('now'))
    `).bind(eventId, userId).run()
    
    // Update bookmark count
    await c.env.DB.prepare(`
      UPDATE events 
      SET bookmark_count = bookmark_count + 1 
      WHERE id = ?
    `).bind(eventId).run()
    
    return c.json({ success: true, message: 'Bookmark added' })
  } catch (error) {
    console.error('Error bookmarking event:', error)
    return c.json({ success: false, error: 'Failed to bookmark' }, 500)
  }
})

// ===== Chat API =====

// Get all chats for current user (protected)
app.get('/api/chats', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    
    const result = await c.env.DB.prepare(`
      SELECT 
        c.*,
        (SELECT COUNT(*) FROM chat_members WHERE chat_id = c.id) as member_count,
        (SELECT MAX(created_at) FROM messages WHERE chat_id = c.id) as last_message_at
      FROM chats c
      INNER JOIN chat_members cm ON c.id = cm.chat_id
      WHERE cm.user_id = ?
      ORDER BY last_message_at DESC NULLS LAST
    `).bind(userId).all()
    
    return c.json({ success: true, chats: result.results || [] })
  } catch (error) {
    console.error('Error fetching chats:', error)
    return c.json({ success: false, error: 'Failed to fetch chats' }, 500)
  }
})

// Create new chat (private or group)
app.post('/api/chats', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const { chat_type, title, description, member_ids } = await c.req.json()
    
    if (!chat_type || !['private', 'group', 'channel'].includes(chat_type)) {
      return c.json({ success: false, error: 'Invalid chat type' }, 400)
    }
    
    if (chat_type === 'private' && (!member_ids || member_ids.length !== 1)) {
      return c.json({ success: false, error: 'Private chat requires exactly one other member' }, 400)
    }
    
    // Check if private chat already exists
    if (chat_type === 'private') {
      const existing = await c.env.DB.prepare(`
        SELECT c.id FROM chats c
        INNER JOIN chat_members cm1 ON c.id = cm1.chat_id
        INNER JOIN chat_members cm2 ON c.id = cm2.chat_id
        WHERE c.chat_type = 'private'
          AND cm1.user_id = ?
          AND cm2.user_id = ?
      `).bind(userId, member_ids[0]).first()
      
      if (existing) {
        return c.json({ success: true, chat_id: existing.id, existing: true })
      }
    }
    
    // Create chat
    const chatResult = await c.env.DB.prepare(`
      INSERT INTO chats (chat_type, title, description, creator_id, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
    `).bind(chat_type, title, description, userId).run()
    
    if (!chatResult.success) {
      return c.json({ success: false, error: 'Failed to create chat' }, 500)
    }
    
    const chatId = chatResult.meta.last_row_id
    
    // Add creator as admin
    await c.env.DB.prepare(`
      INSERT INTO chat_members (chat_id, user_id, role, joined_at)
      VALUES (?, ?, 'admin', datetime('now'))
    `).bind(chatId, userId).run()
    
    // Add other members
    if (member_ids && member_ids.length > 0) {
      for (const memberId of member_ids) {
        await c.env.DB.prepare(`
          INSERT INTO chat_members (chat_id, user_id, role, joined_at)
          VALUES (?, ?, 'member', datetime('now'))
        `).bind(chatId, memberId).run()
      }
    }
    
    return c.json({ success: true, chat_id: chatId })
  } catch (error) {
    console.error('Error creating chat:', error)
    return c.json({ success: false, error: 'Failed to create chat' }, 500)
  }
})

// Get messages for a chat (protected)
app.get('/api/chats/:id/messages', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const chatId = c.req.param('id')
    const limit = parseInt(c.req.query('limit') || '50')
    const before = c.req.query('before') // Message ID for pagination
    
    // Check if user is member
    const membership = await c.env.DB.prepare(`
      SELECT id FROM chat_members WHERE chat_id = ? AND user_id = ?
    `).bind(chatId, userId).first()
    
    if (!membership) {
      return c.json({ success: false, error: 'Not a member of this chat' }, 403)
    }
    
    let sql = `
      SELECT 
        m.*,
        u.username as sender_username,
        u.display_name as sender_display_name,
        u.avatar_url as sender_avatar_url
      FROM messages m
      INNER JOIN users u ON m.sender_id = u.id
      WHERE m.chat_id = ? AND m.is_deleted = 0
    `
    const params: any[] = [chatId]
    
    if (before) {
      sql += ` AND m.id < ?`
      params.push(before)
    }
    
    sql += ` ORDER BY m.created_at DESC LIMIT ?`
    params.push(limit)
    
    const result = await c.env.DB.prepare(sql).bind(...params).all()
    
    // Reverse to get chronological order
    const messages = (result.results || []).reverse()
    
    return c.json({ success: true, messages })
  } catch (error) {
    console.error('Error fetching messages:', error)
    return c.json({ success: false, error: 'Failed to fetch messages' }, 500)
  }
})

// Send message (protected)
app.post('/api/chats/:id/messages', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const chatId = c.req.param('id')
    const { content, message_type, reply_to_message_id } = await c.req.json()
    
    if (!content) {
      return c.json({ success: false, error: 'Message content is required' }, 400)
    }
    
    // Check if user is member
    const membership = await c.env.DB.prepare(`
      SELECT id FROM chat_members WHERE chat_id = ? AND user_id = ?
    `).bind(chatId, userId).first()
    
    if (!membership) {
      return c.json({ success: false, error: 'Not a member of this chat' }, 403)
    }
    
    // Create message
    const result = await c.env.DB.prepare(`
      INSERT INTO messages (chat_id, sender_id, content, message_type, reply_to_message_id, created_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    `).bind(chatId, userId, content, message_type || 'text', reply_to_message_id || null).run()
    
    if (!result.success) {
      return c.json({ success: false, error: 'Failed to send message' }, 500)
    }
    
    const messageId = result.meta.last_row_id
    
    // Get the created message with user info
    const message = await c.env.DB.prepare(`
      SELECT 
        m.*,
        u.username as sender_username,
        u.display_name as sender_display_name,
        u.avatar_url as sender_avatar_url
      FROM messages m
      INNER JOIN users u ON m.sender_id = u.id
      WHERE m.id = ?
    `).bind(messageId).first()
    
    return c.json({ success: true, message })
  } catch (error) {
    console.error('Error sending message:', error)
    return c.json({ success: false, error: 'Failed to send message' }, 500)
  }
})

// Get chat members (protected)
app.get('/api/chats/:id/members', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const chatId = c.req.param('id')
    
    // Check if user is member
    const membership = await c.env.DB.prepare(`
      SELECT id FROM chat_members WHERE chat_id = ? AND user_id = ?
    `).bind(chatId, userId).first()
    
    if (!membership) {
      return c.json({ success: false, error: 'Not a member of this chat' }, 403)
    }
    
    const result = await c.env.DB.prepare(`
      SELECT 
        cm.role,
        cm.joined_at,
        u.id,
        u.username,
        u.display_name,
        u.avatar_url,
        u.status,
        u.last_seen
      FROM chat_members cm
      INNER JOIN users u ON cm.user_id = u.id
      WHERE cm.chat_id = ?
      ORDER BY cm.role DESC, u.username ASC
    `).bind(chatId).all()
    
    return c.json({ success: true, members: result.results || [] })
  } catch (error) {
    console.error('Error fetching members:', error)
    return c.json({ success: false, error: 'Failed to fetch members' }, 500)
  }
})

// Search users (protected)
app.get('/api/users/search', authMiddleware, async (c) => {
  try {
    const query = c.req.query('q') || ''
    
    if (query.length < 2) {
      return c.json({ success: true, users: [] })
    }
    
    const result = await c.env.DB.prepare(`
      SELECT id, username, display_name, avatar_url, status
      FROM users
      WHERE username LIKE ? OR display_name LIKE ?
      LIMIT 20
    `).bind(`%${query}%`, `%${query}%`).all()
    
    return c.json({ success: true, users: result.results || [] })
  } catch (error) {
    console.error('Error searching users:', error)
    return c.json({ success: false, error: 'Failed to search users' }, 500)
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
          
          /* Event Detail Modal */
          .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(10px);
            z-index: 10000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            animation: fadeIn 0.3s ease;
          }
          
          @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
          }
          
          .modal-content {
            background: rgba(26, 26, 46, 0.98);
            border: 2px solid rgba(255, 215, 0, 0.5);
            border-radius: 15px;
            max-width: 800px;
            width: 100%;
            max-height: 90vh;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: 0 10px 50px rgba(0, 0, 0, 0.7);
            animation: slideUp 0.3s ease;
          }
          
          @keyframes slideUp {
            from { transform: translateY(50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
          }
          
          .modal-header {
            padding: 20px 25px;
            border-bottom: 1px solid rgba(255, 215, 0, 0.3);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: rgba(255, 215, 0, 0.05);
          }
          
          .modal-header h2 {
            font-size: 24px;
            font-weight: bold;
            color: #ffd700;
            margin: 0;
          }
          
          .modal-close {
            background: none;
            border: none;
            color: rgba(255, 255, 255, 0.7);
            font-size: 24px;
            cursor: pointer;
            transition: all 0.3s;
            padding: 5px 10px;
          }
          
          .modal-close:hover {
            color: #ffd700;
            transform: rotate(90deg);
          }
          
          .modal-body {
            padding: 25px;
            overflow-y: auto;
            flex: 1;
          }
          
          .modal-body::-webkit-scrollbar {
            width: 8px;
          }
          
          .modal-body::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.05);
          }
          
          .modal-body::-webkit-scrollbar-thumb {
            background: rgba(255, 215, 0, 0.3);
            border-radius: 4px;
          }
          
          .event-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-bottom: 20px;
          }
          
          .meta-badge {
            padding: 6px 12px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 215, 0, 0.3);
            border-radius: 20px;
            font-size: 13px;
            color: rgba(255, 255, 255, 0.9);
          }
          
          .meta-badge i {
            color: #ffd700;
            margin-right: 5px;
          }
          
          .evidence-proven {
            background: rgba(0, 255, 0, 0.2);
            border-color: #00ff00;
          }
          
          .evidence-documented {
            background: rgba(0, 150, 255, 0.2);
            border-color: #0096ff;
          }
          
          .evidence-military {
            background: rgba(255, 150, 0, 0.2);
            border-color: #ff9600;
          }
          
          .evidence-speculative {
            background: rgba(147, 112, 219, 0.2);
            border-color: #9370db;
          }
          
          .event-description,
          .event-full-description,
          .event-sources,
          .event-keywords {
            margin-bottom: 25px;
          }
          
          .event-description h3,
          .event-full-description h3,
          .event-sources h3,
          .event-keywords h3 {
            font-size: 18px;
            font-weight: bold;
            color: #ffd700;
            margin-bottom: 12px;
          }
          
          .event-description p,
          .full-text {
            font-size: 15px;
            line-height: 1.7;
            color: rgba(255, 255, 255, 0.9);
          }
          
          .full-text {
            background: rgba(255, 255, 255, 0.05);
            padding: 15px;
            border-radius: 8px;
            border-left: 3px solid #ffd700;
          }
          
          .event-sources ul {
            list-style: none;
            padding: 0;
          }
          
          .event-sources li {
            padding: 10px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 5px;
            margin-bottom: 8px;
            border-left: 3px solid rgba(255, 215, 0, 0.5);
          }
          
          .event-sources li strong {
            color: #ffd700;
          }
          
          .keywords-container {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
          }
          
          .keyword-tag {
            padding: 6px 12px;
            background: rgba(255, 215, 0, 0.15);
            border: 1px solid rgba(255, 215, 0, 0.4);
            border-radius: 15px;
            font-size: 13px;
            color: #ffd700;
          }
          
          .event-stats {
            display: flex;
            gap: 20px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 215, 0, 0.2);
            color: rgba(255, 255, 255, 0.6);
            font-size: 14px;
          }
          
          .event-stats i {
            color: #ffd700;
            margin-right: 5px;
          }
          
          .modal-footer {
            padding: 20px 25px;
            border-top: 1px solid rgba(255, 215, 0, 0.3);
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            background: rgba(255, 215, 0, 0.05);
          }
          
          .btn-primary,
          .btn-secondary {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
          }
          
          .btn-primary {
            background: linear-gradient(135deg, #ffd700, #ffed4e);
            color: #1a1a2e;
          }
          
          .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(255, 215, 0, 0.4);
          }
          
          .btn-secondary {
            background: rgba(255, 255, 255, 0.1);
            color: rgba(255, 255, 255, 0.9);
            border: 1px solid rgba(255, 255, 255, 0.3);
          }
          
          .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.15);
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
            
            .modal-content {
              max-width: 100%;
              max-height: 95vh;
            }
            
            .modal-header h2 {
              font-size: 20px;
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
            <div class="flex gap-2">
                <button onclick="window.location.href='/static/chat.html'" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition">
                    <i class="fas fa-comments mr-2"></i>
                    Chat
                </button>
                <button onclick="toggleFilters()" class="px-4 py-2 bg-yellow-600 hover:bg-yellow-700 rounded-lg transition">
                    <i class="fas fa-filter mr-2"></i>
                    Filter
                </button>
                <button id="auth-button" onclick="handleAuth()" class="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg transition">
                    <i class="fas fa-sign-in-alt mr-2"></i>
                    <span id="auth-text">Login</span>
                </button>
            </div>
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
        
        <script>
          // Auth handling
          function checkAuthStatus() {
            const token = localStorage.getItem('auth_token');
            const user = localStorage.getItem('user');
            const authButton = document.getElementById('auth-button');
            const authText = document.getElementById('auth-text');
            
            if (token && user) {
              const userData = JSON.parse(user);
              authText.textContent = userData.username;
              authButton.classList.remove('bg-green-600', 'hover:bg-green-700');
              authButton.classList.add('bg-red-600', 'hover:bg-red-700');
              authButton.innerHTML = '<i class="fas fa-sign-out-alt mr-2"></i><span>' + userData.username + '</span>';
            } else {
              authText.textContent = 'Login';
            }
          }
          
          function handleAuth() {
            const token = localStorage.getItem('auth_token');
            if (token) {
              // Logout
              if (confirm('Möchtest du dich abmelden?')) {
                localStorage.removeItem('auth_token');
                localStorage.removeItem('user');
                window.location.reload();
              }
            } else {
              // Redirect to login
              window.location.href = '/static/auth.html';
            }
          }
          
          // Check auth on load
          document.addEventListener('DOMContentLoaded', checkAuthStatus);
        </script>
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
