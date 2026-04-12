-- Inject 'coding' and 'music' interests to the dummy users
-- so the matching engine calculates a >0 similarity score for the logged-in user.

-- Ensure the interests exist (in case the UI saved them with different casing or we need a fallback)
INSERT INTO interests (id, name) VALUES (201, 'coding') ON CONFLICT DO NOTHING;
INSERT INTO interests (id, name) VALUES (202, 'music') ON CONFLICT DO NOTHING;

-- Assign 'coding' to all 5 dummy users
DO $$
DECLARE
    coding_id INT;
    music_id INT;
BEGIN
    SELECT id INTO coding_id FROM interests WHERE name ILIKE 'coding' LIMIT 1;
    SELECT id INTO music_id FROM interests WHERE name ILIKE 'music' LIMIT 1;

    IF coding_id IS NOT NULL THEN
        INSERT INTO user_interests (user_id, interest_id) VALUES
            ('a0000000-0000-0000-0000-000000000001', coding_id),
            ('a0000000-0000-0000-0000-000000000002', coding_id),
            ('a0000000-0000-0000-0000-000000000003', coding_id),
            ('a0000000-0000-0000-0000-000000000004', coding_id),
            ('a0000000-0000-0000-0000-000000000005', coding_id),
            ('a0000000-0000-0000-0000-000000000abc', coding_id)
        ON CONFLICT DO NOTHING;
    END IF;

    IF music_id IS NOT NULL THEN
        INSERT INTO user_interests (user_id, interest_id) VALUES
            ('a0000000-0000-0000-0000-000000000001', music_id),
            ('a0000000-0000-0000-0000-000000000004', music_id),
            ('a0000000-0000-0000-0000-000000000abc', music_id)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
