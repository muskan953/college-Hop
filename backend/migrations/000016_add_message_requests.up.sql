-- 000016_add_message_requests.up.sql

-- Add requester_id to connections to track who initiated the pending request
ALTER TABLE connections 
  ADD COLUMN IF NOT EXISTS requester_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Add request flags to threads
ALTER TABLE message_threads
  ADD COLUMN IF NOT EXISTS is_request BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS request_message_count INTEGER NOT NULL DEFAULT 0;
