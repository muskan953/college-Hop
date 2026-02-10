CREATE TABLE IF NOT EXISTS otp_verifications (
        id UUID PRIMARY KEY,
        email TEXT NOT NULL,
        otp_hash TEXT NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        used BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
