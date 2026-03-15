-- Add alternate email to profiles
ALTER TABLE profiles ADD COLUMN alternate_email TEXT;

-- Connections between users
CREATE TABLE IF NOT EXISTS connections (
    user_id_1 UUID REFERENCES users(id) ON DELETE CASCADE,
    user_id_2 UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'connected',
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id_1, user_id_2)
);

-- User preferences for privacy and notifications settings
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_visibility VARCHAR(50) DEFAULT 'public',
    show_location BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    new_match_alerts BOOLEAN DEFAULT true,
    message_alerts BOOLEAN DEFAULT true,
    updated_at TIMESTAMP DEFAULT NOW()
);
