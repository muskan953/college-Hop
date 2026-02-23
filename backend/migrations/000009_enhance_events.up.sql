-- Rename existing columns for clarity
ALTER TABLE events RENAME COLUMN location TO venue;
ALTER TABLE events RENAME COLUMN url TO event_link;
ALTER TABLE events RENAME COLUMN date TO start_date;

-- Add new fields for enhanced event submission
ALTER TABLE events ADD COLUMN end_date TIMESTAMP;
ALTER TABLE events ADD COLUMN category VARCHAR(100);
ALTER TABLE events ADD COLUMN time_description VARCHAR(255);
ALTER TABLE events ADD COLUMN brochure_url VARCHAR(512);
ALTER TABLE events ADD COLUMN ticket_link VARCHAR(512);
