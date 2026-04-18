-- 000016_add_message_requests.down.sql

ALTER TABLE message_threads
  DROP COLUMN IF EXISTS is_request,
  DROP COLUMN IF EXISTS request_message_count;

ALTER TABLE connections 
  DROP COLUMN IF EXISTS requester_id;
