CREATE TABLE profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

    full_name TEXT NOT NULL,
    college_name TEXT NOT NULL,
    major TEXT NOT NULL,
    roll_number TEXT NOT NULL,
    id_expiration DATE NOT NULL,

    bio TEXT,
    profile_photo_url TEXT,
    college_id_card_url TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
