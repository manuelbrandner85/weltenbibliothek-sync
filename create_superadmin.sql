-- Create Super Admin Account
-- Username: Weltenbibliothek
-- Password: Jolene2305
-- Password Hash: SHA-256 of "Jolene2305"

-- First, add role column if not exists (for backwards compatibility)
-- ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';

-- Delete existing if any
DELETE FROM users WHERE username = 'Weltenbibliothek';

-- Create Super Admin
-- Password hash for "Jolene2305" = b5a2c96250612366ea272ffac6d9744aaf4b45aacd96aa7cfcb931ee3b558259
INSERT INTO users (
  username, 
  email, 
  password_hash, 
  display_name, 
  is_admin,
  is_verified,
  status,
  created_at
) VALUES (
  'Weltenbibliothek',
  'superadmin@weltenbibliothek.local',
  'b5a2c96250612366ea272ffac6d9744aaf4b45aacd96aa7cfcb931ee3b558259',
  'Super Admin',
  1,
  1,
  'online',
  datetime('now')
);

-- Verify creation
SELECT id, username, display_name, is_admin FROM users WHERE username = 'Weltenbibliothek';
