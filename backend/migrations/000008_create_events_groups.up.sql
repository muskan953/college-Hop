-- Events table (community-sourced, admin-verified)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    date TIMESTAMP NOT NULL,
    location VARCHAR(255) NOT NULL,
    organizer VARCHAR(255) NOT NULL,
    url VARCHAR(512),
    submitted_by UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

-- User-event relationship (selected event, interest status)
CREATE TABLE IF NOT EXISTS user_events (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'interested',
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, event_id)
);

-- Travel groups for events
CREATE TABLE IF NOT EXISTS travel_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    max_members INT DEFAULT 4,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Group membership
CREATE TABLE IF NOT EXISTS group_members (
    group_id UUID REFERENCES travel_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);
