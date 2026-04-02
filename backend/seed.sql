-- seed.sql: Creates dummy data for testing MyEvent dashboard

-- 1. Create a dummy event for next week
INSERT INTO events (id, name, start_date, venue, organizer, event_link, status, category)
VALUES (
    'c0000000-0000-0000-0000-000000000000',
    'Dummy Hackathon 2026',
    NOW() + INTERVAL '7 days',
    'San Francisco, CA',
    'CollegeHop Team',
    'https://example.com',
    'approved',
    'Hackathon'
) ON CONFLICT (id) DO UPDATE SET start_date = EXCLUDED.start_date;

-- 2. Create 5 dummy users
INSERT INTO users (id, email)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'test1@example.com'),
    ('a0000000-0000-0000-0000-000000000002', 'test2@example.com'),
    ('a0000000-0000-0000-0000-000000000003', 'test3@example.com'),
    ('a0000000-0000-0000-0000-000000000004', 'test4@example.com'),
    ('a0000000-0000-0000-0000-000000000005', 'test5@example.com')
ON CONFLICT DO NOTHING;

-- 3. Create profiles for them
INSERT INTO profiles (user_id, full_name, college_name, major, roll_number, id_expiration, bio, profile_photo_url)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Priya Sharma', 'MIT', 'Computer Science', 'R01', '2028-01-01', 'Love coding!', 'https://i.pravatar.cc/150?u=1'),
    ('a0000000-0000-0000-0000-000000000002', 'Rahul Patel', 'Stanford', 'Electrical Engineering', 'R02', '2028-01-01', 'Hardware hacker', 'https://i.pravatar.cc/150?u=2'),
    ('a0000000-0000-0000-0000-000000000003', 'Ananya Singh', 'UC Berkeley', 'Data Science', 'R03', '2028-01-01', 'Data is beautiful', 'https://i.pravatar.cc/150?u=3'),
    ('a0000000-0000-0000-0000-000000000004', 'Vikram Desai', 'IIT Delhi', 'Software Eng', 'R04', '2028-01-01', 'Full stack dev', 'https://i.pravatar.cc/150?u=4'),
    ('a0000000-0000-0000-0000-000000000005', 'Neha Gupta', 'NYU', 'Design', 'R05', '2028-01-01', 'UI/UX enthusiast', 'https://i.pravatar.cc/150?u=5')
ON CONFLICT DO NOTHING;

-- 4. Create common interests
INSERT INTO interests (id, name) VALUES
    (101, 'AI'),
    (102, 'Startups'),
    (103, 'Python'),
    (104, 'Machine Learning'),
    (105, 'Web Dev')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- 5. Assign interests to dummy users
INSERT INTO user_interests (user_id, interest_id) VALUES
    ('a0000000-0000-0000-0000-000000000001', 101), ('a0000000-0000-0000-0000-000000000001', 102), ('a0000000-0000-0000-0000-000000000001', 103),
    ('a0000000-0000-0000-0000-000000000002', 103), ('a0000000-0000-0000-0000-000000000002', 104), -- shares Python with u1
    ('a0000000-0000-0000-0000-000000000003', 102), ('a0000000-0000-0000-0000-000000000003', 104), -- shares Startups with u1
    ('a0000000-0000-0000-0000-000000000004', 105), ('a0000000-0000-0000-0000-000000000004', 101), -- shares AI with u1
    ('a0000000-0000-0000-0000-000000000005', 105)
ON CONFLICT DO NOTHING;

-- 6. Enroll all dummy users into the "Dummy Hackathon 2026" event
INSERT INTO user_events (user_id, event_id, status) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000000', 'interested'),
    ('a0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000000', 'interested'),
    ('a0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000000', 'interested'),
    ('a0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000000', 'interested'),
    ('a0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000000', 'interested')
ON CONFLICT DO NOTHING;

-- 7. Create 2 dummy travel groups for this event
INSERT INTO travel_groups (id, event_id, name, description, created_by, max_members, departure_date, meeting_point) VALUES
    ('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000000', 'AI & Hackers Group', 'Lets code AI projects together', 'a0000000-0000-0000-0000-000000000001', 4, NOW() + INTERVAL '5 days', 'SFO Terminal 2'),
    ('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000000', 'Web Dev Startups', 'Looking for frontend devs', 'a0000000-0000-0000-0000-000000000004', 4, NOW() + INTERVAL '6 days', 'Union Square')
ON CONFLICT DO NOTHING;

-- 8. Add members to groups
INSERT INTO group_members (group_id, user_id) VALUES
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001'),
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002'),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000004'),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005')
ON CONFLICT DO NOTHING;
