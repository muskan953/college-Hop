-- Reverse new fields
ALTER TABLE events DROP COLUMN IF EXISTS ticket_link;
ALTER TABLE events DROP COLUMN IF EXISTS brochure_url;
ALTER TABLE events DROP COLUMN IF EXISTS time_description;
ALTER TABLE events DROP COLUMN IF EXISTS category;
ALTER TABLE events DROP COLUMN IF EXISTS end_date;

-- Reverse column renames
ALTER TABLE events RENAME COLUMN start_date TO date;
ALTER TABLE events RENAME COLUMN event_link TO url;
ALTER TABLE events RENAME COLUMN venue TO location;
