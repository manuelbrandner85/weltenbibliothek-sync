-- Extend events table with detailed content fields
ALTER TABLE events ADD COLUMN full_description TEXT;
ALTER TABLE events ADD COLUMN sources TEXT; -- JSON array of sources
ALTER TABLE events ADD COLUMN related_events TEXT; -- JSON array of related event IDs
ALTER TABLE events ADD COLUMN keywords TEXT; -- JSON array of keywords
ALTER TABLE events ADD COLUMN view_count INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN comment_count INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN bookmark_count INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN evidence_level TEXT; -- speculative, documented, proven
ALTER TABLE events ADD COLUMN content_warning TEXT; -- optional warning for sensitive content

-- Create full-text search for events
CREATE VIRTUAL TABLE IF NOT EXISTS events_fts USING fts5(
  title,
  description,
  full_description,
  keywords,
  content='events',
  content_rowid='id'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS events_ai AFTER INSERT ON events BEGIN
  INSERT INTO events_fts(rowid, title, description, full_description, keywords)
  VALUES (new.id, new.title, new.description, new.full_description, new.keywords);
END;

CREATE TRIGGER IF NOT EXISTS events_ad AFTER DELETE ON events BEGIN
  DELETE FROM events_fts WHERE rowid = old.id;
END;

CREATE TRIGGER IF NOT EXISTS events_au AFTER UPDATE ON events BEGIN
  UPDATE events_fts 
  SET title = new.title, 
      description = new.description,
      full_description = new.full_description,
      keywords = new.keywords
  WHERE rowid = new.id;
END;
