-- Create events table for map markers
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  category TEXT,
  event_type TEXT, -- conspiracy, ancient, ufo, mystery, etc.
  year INTEGER,
  date_text TEXT,
  icon_type TEXT, -- marker icon identifier
  image_url TEXT,
  related_document_id INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (related_document_id) REFERENCES documents(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_events_latitude ON events(latitude);
CREATE INDEX IF NOT EXISTS idx_events_longitude ON events(longitude);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_year ON events(year);
