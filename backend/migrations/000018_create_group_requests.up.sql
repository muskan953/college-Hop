ALTER TABLE travel_groups ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS group_join_requests (
    group_id UUID REFERENCES travel_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    requested_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);
