-- Create Default Chats: Allgemein + Musik
-- These are public channels that exist for all users

-- Create a system user for default chats (if not exists)
INSERT OR IGNORE INTO users (id, username, email, password_hash, display_name, is_admin, is_verified, status, created_at)
VALUES (0, 'System', 'system@weltenbibliothek.local', '', 'Weltenbibliothek System', 1, 1, 'online', datetime('now'));

-- Create Allgemein Chat (General Discussion)
INSERT OR IGNORE INTO chats (id, chat_type, title, description, avatar_url, creator_id, is_public, created_at)
VALUES (
  1,
  'channel',
  '💬 Allgemein',
  'Allgemeiner Chat für alle Themen - Alternative Theorien, Mysterien, und mehr. Respektvoller Austausch erwünscht.',
  null,
  0,
  1,
  datetime('now')
);

-- Create Musik Chat (Music Discussion)
INSERT OR IGNORE INTO chats (id, chat_type, title, description, avatar_url, creator_id, is_public, created_at)
VALUES (
  2,
  'channel',
  '🎵 Musik',
  'Teile deine Lieblingssongs, diskutiere über Musik-Mysterien und entdecke neue Künstler. Von klassisch bis modern.',
  null,
  0,
  1,
  datetime('now')
);

-- Add welcome messages to Allgemein
INSERT OR IGNORE INTO messages (chat_id, sender_id, message_type, content, created_at)
VALUES (
  1,
  0,
  'text',
  'Willkommen im Allgemein-Chat! 👋

Hier könnt ihr euch über alle Themen austauschen:
• Alternative Theorien & Verborgenes Wissen
• Mysteriöse Events & Phänomene
• Eure eigenen Entdeckungen

Bitte beachtet: Respektvoller Umgang, keine Beleidigungen, keine Spam-Nachrichten.

Viel Spaß beim Austausch! 🌟',
  datetime('now')
);

-- Add welcome message to Musik
INSERT OR IGNORE INTO messages (chat_id, sender_id, message_type, content, created_at)
VALUES (
  2,
  0,
  'text',
  'Willkommen im Musik-Chat! 🎵

Hier dreht sich alles um Musik:
• Teile deine Lieblingssongs
• Diskutiere über Musik-Mysterien (Rückwärts-Botschaften, etc.)
• Entdecke neue Künstler
• Livestreams & Jam-Sessions

Let the music play! 🎸🎹🎤',
  datetime('now')
);

-- Note: Users will auto-join these public channels on first access
