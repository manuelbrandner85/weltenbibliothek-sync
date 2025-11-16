-- Add role system to users table
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';

-- Update existing Super Admin
UPDATE users SET role = 'superadmin' WHERE username = 'Weltenbibliothek';

-- Create index
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
