ALTER TABLE messages
DROP COLUMN IF EXISTS reply_to_id,
DROP COLUMN IF EXISTS is_forwarded;
