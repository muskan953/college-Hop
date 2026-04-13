ALTER TABLE thread_participants ADD COLUMN last_read_at TIMESTAMPTZ DEFAULT '1970-01-01'::timestamptz;
