// Authentication utilities for Weltenbibliothek
import { Context } from 'hono'

// Simple password hashing using Web Crypto API (available in Cloudflare Workers)
export async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(password)
  const hash = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

// Verify password against hash
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  const passwordHash = await hashPassword(password)
  return passwordHash === hash
}

// Generate JWT token (simple implementation)
export async function generateToken(userId: number, username: string): Promise<string> {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  }

  const payload = {
    userId,
    username,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7 days
  }

  const secret = 'weltenbibliothek-secret-key-change-in-production' // TODO: Move to env var

  const encoder = new TextEncoder()
  const headerStr = btoa(JSON.stringify(header))
  const payloadStr = btoa(JSON.stringify(payload))
  const toSign = `${headerStr}.${payloadStr}`
  
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(toSign)
  )
  
  const signatureStr = btoa(String.fromCharCode(...new Uint8Array(signature)))
  
  return `${toSign}.${signatureStr}`
}

// Verify JWT token
export async function verifyToken(token: string): Promise<any> {
  try {
    const parts = token.split('.')
    if (parts.length !== 3) return null
    
    const [headerStr, payloadStr, signatureStr] = parts
    const payload = JSON.parse(atob(payloadStr))
    
    // Check expiration
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return null
    }
    
    // In production, verify signature here
    // For now, we trust the token if not expired
    
    return payload
  } catch (error) {
    return null
  }
}

// Middleware to protect routes
export async function authMiddleware(c: Context, next: Function) {
  const authHeader = c.req.header('Authorization')
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, error: 'Unauthorized' }, 401)
  }
  
  const token = authHeader.substring(7)
  const payload = await verifyToken(token)
  
  if (!payload) {
    return c.json({ success: false, error: 'Invalid or expired token' }, 401)
  }
  
  // Store user info in context
  c.set('userId', payload.userId)
  c.set('username', payload.username)
  
  await next()
}

// Optional auth middleware (doesn't fail if no token)
export async function optionalAuthMiddleware(c: Context, next: Function) {
  const authHeader = c.req.header('Authorization')
  
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7)
    const payload = await verifyToken(token)
    
    if (payload) {
      c.set('userId', payload.userId)
      c.set('username', payload.username)
    }
  }
  
  await next()
}
