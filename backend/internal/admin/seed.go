package admin

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Fixed UUIDs for seed data — chosen to be clearly non-production
// Events: e0000000-seed-0000-0000-00000000000x
// Users:  d0000000-seed-0000-0000-00000000000x
var seedEventIDs = []string{
	"e0000000-5eed-0000-0000-000000000001",
	"e0000000-5eed-0000-0000-000000000002",
	"e0000000-5eed-0000-0000-000000000003",
	"e0000000-5eed-0000-0000-000000000004",
	"e0000000-5eed-0000-0000-000000000005",
}

var seedGroupIDs = []string{
	"g0000000-5eed-0000-0000-000000000001",
	"g0000000-5eed-0000-0000-000000000002",
	"g0000000-5eed-0000-0000-000000000003",
}

var seedUserIDs = []string{
	"d0000000-5eed-0000-0000-000000000001",
	"d0000000-5eed-0000-0000-000000000002",
	"d0000000-5eed-0000-0000-000000000003",
	"d0000000-5eed-0000-0000-000000000004",
	"d0000000-5eed-0000-0000-000000000005",
	"d0000000-5eed-0000-0000-000000000006",
	"d0000000-5eed-0000-0000-000000000007",
	"d0000000-5eed-0000-0000-000000000008",
}

// SeedHandler handles dummy data injection for testing/demo purposes.
type SeedHandler struct {
	db *sql.DB
}

func NewSeedHandler(db *sql.DB) *SeedHandler {
	return &SeedHandler{db: db}
}

// SeedDummyData seeds dummy users, profiles, events, and enrollments.
// POST /admin/seed
func (h *SeedHandler) SeedDummyData(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()
	results := map[string]interface{}{}

	eventsSeeded, err := h.seedEvents(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to seed events: %v", err), http.StatusInternalServerError)
		return
	}
	results["events_seeded"] = eventsSeeded

	usersSeeded, err := h.seedUsers(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to seed users: %v", err), http.StatusInternalServerError)
		return
	}
	results["users_seeded"] = usersSeeded

	h.seedInterests(ctx)
	h.seedEnrollments(ctx)
	h.seedGroups(ctx)

	results["message"] = "Dummy data seeded successfully"
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

// ClearDummyData removes all seeded dummy data.
// POST /admin/seed/clear
func (h *SeedHandler) ClearDummyData(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ctx := r.Context()

	// Build quoted ID lists for SQL IN clauses
	eventIDList := uuidList(seedEventIDs)
	userIDList := uuidList(seedUserIDs)
	groupIDList := uuidList(seedGroupIDs)

	// Delete in reverse dependency order
	h.db.ExecContext(ctx, `DELETE FROM group_members WHERE group_id IN (`+groupIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM group_members WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM travel_groups WHERE id IN (`+groupIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM user_events WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM user_events WHERE event_id IN (`+eventIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM user_interests WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM profiles WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM users WHERE id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM events WHERE id IN (`+eventIDList+`)`)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Dummy data cleared"})
}

// uuidList builds a SQL-safe comma-separated list of quoted UUIDs
func uuidList(ids []string) string {
	result := ""
	for i, id := range ids {
		if i > 0 {
			result += ","
		}
		result += "'" + id + "'"
	}
	return result
}

func (h *SeedHandler) seedEvents(ctx context.Context) (int, error) {
	type seedEvent struct {
		id, name, venue, organizer, link, category string
		daysFromNow                                 int
	}

	events := []seedEvent{
		{seedEventIDs[0], "TechFest 2026", "IIT Bombay, Mumbai", "IIT Bombay", "https://techfest.org", "Hackathon", 14},
		{seedEventIDs[1], "Hack With India", "BITS Pilani, Rajasthan", "BITS Pilani", "https://hackwithindia.com", "Hackathon", 21},
		{seedEventIDs[2], "National Science Conclave", "IISc Bangalore, Karnataka", "IISc Bangalore", "https://iisc.ac.in", "Conference", 30},
		{seedEventIDs[3], "Startup Summit 2026", "SRCC, New Delhi", "SRCC Delhi", "https://startupsummit.in", "Summit", 10},
		{seedEventIDs[4], "Atmos Cultural Fest", "BITS Hyderabad, Telangana", "BITS Hyderabad", "https://atmos.bits-hyderabad.ac.in", "Cultural", 7},
	}

	count := 0
	for _, e := range events {
		startDate := time.Now().Add(time.Duration(e.daysFromNow) * 24 * time.Hour)
		res, err := h.db.ExecContext(ctx, `
			INSERT INTO events (id, name, start_date, venue, organizer, event_link, status, category)
			VALUES ($1, $2, $3, $4, $5, $6, 'approved', $7)
			ON CONFLICT (id) DO NOTHING
		`, e.id, e.name, startDate, e.venue, e.organizer, e.link, e.category)
		if err != nil {
			return count, err
		}
		if n, _ := res.RowsAffected(); n > 0 {
			count++
		}
	}
	return count, nil
}

func (h *SeedHandler) seedUsers(ctx context.Context) (int, error) {
	type seedUser struct {
		id, email, name, college, major, roll, bio, photo string
	}

	users := []seedUser{
		{seedUserIDs[0], "arjun.sharma@iitb.ac.in", "Arjun Sharma", "IIT Bombay", "Computer Science", "200010001", "Passionate about AI and robotics 🤖", "https://i.pravatar.cc/150?u=arjun"},
		{seedUserIDs[1], "priya.patel@bits-pilani.ac.in", "Priya Patel", "BITS Pilani", "Electronics Eng", "2020A3PS001P", "Electronics enthusiast and hackathon winner ⚡", "https://i.pravatar.cc/150?u=priya"},
		{seedUserIDs[2], "rahul.kumar@iisc.ac.in", "Rahul Kumar", "IISc Bangalore", "Data Science", "DS2021001", "Research-focused student in ML 📊", "https://i.pravatar.cc/150?u=rahul"},
		{seedUserIDs[3], "sneha.reddy@srcc.du.ac.in", "Sneha Reddy", "SRCC Delhi", "Economics", "EC2022045", "Finance and entrepreneurship 💼", "https://i.pravatar.cc/150?u=sneha"},
		{seedUserIDs[4], "vikram.nair@vitchennai.ac.in", "Vikram Nair", "VIT Chennai", "Software Engineering", "20BCE1234", "Full stack developer building cool stuff 🚀", "https://i.pravatar.cc/150?u=vikram"},
		{seedUserIDs[5], "ananya.singh@manipal.edu", "Ananya Singh", "Manipal University", "Design", "200906789", "UI/UX enthusiast who loves Figma 🎨", "https://i.pravatar.cc/150?u=ananya"},
		{seedUserIDs[6], "karthik.m@psgtech.ac.in", "Karthik M", "PSG College of Technology", "Mechanical Eng", "19ME001", "Robotics and automation nerd 🔧", "https://i.pravatar.cc/150?u=karthik"},
		{seedUserIDs[7], "divya.joshi@iitd.ac.in", "Divya Joshi", "IIT Delhi", "Physics", "PH21001", "Quantum computing researcher ⚛️", "https://i.pravatar.cc/150?u=divya"},
	}

	count := 0
	for _, u := range users {
		res, err := h.db.ExecContext(ctx, `
			INSERT INTO users (id, email, status) VALUES ($1, $2, 'verified')
			ON CONFLICT (id) DO NOTHING
		`, u.id, u.email)
		if err != nil {
			return count, err
		}
		if n, _ := res.RowsAffected(); n > 0 {
			count++
		}

		_, err = h.db.ExecContext(ctx, `
			INSERT INTO profiles (user_id, full_name, college_name, major, roll_number, id_expiration, bio, profile_photo_url)
			VALUES ($1, $2, $3, $4, $5, '2028-01-01', $6, $7)
			ON CONFLICT (user_id) DO NOTHING
		`, u.id, u.name, u.college, u.major, u.roll, u.bio, u.photo)
		if err != nil {
			return count, err
		}
	}
	return count, nil
}

func (h *SeedHandler) seedInterests(ctx context.Context) {
	// Fetch all existing interests from the DB by name so we use the correct IDs
	rows, err := h.db.QueryContext(ctx, `SELECT id, name FROM interests`)
	if err != nil {
		return
	}
	defer rows.Close()

	interestMap := map[string]int{}
	for rows.Next() {
		var id int
		var name string
		if rows.Scan(&id, &name) == nil {
			interestMap[name] = id
		}
	}

	// Assign interests that OVERLAP with Shivam's so matching shows these users
	// Shivam has: Programming, Design, Startups, Gaming, Music, Reading, Movies, Coding
	userInterests := map[string][]string{
		seedUserIDs[0]: {"Programming", "Startups", "Gaming"},  // Arjun
		seedUserIDs[1]: {"Programming", "Design", "Music"},     // Priya
		seedUserIDs[2]: {"Gaming", "Movies", "Reading"},        // Rahul
		seedUserIDs[3]: {"Design", "Startups", "Reading"},      // Sneha
		seedUserIDs[4]: {"Programming", "Startups", "Coding"},  // Vikram
		seedUserIDs[5]: {"Design", "Music", "Movies"},          // Ananya
		seedUserIDs[6]: {"Programming", "Gaming", "Reading"},   // Karthik
		seedUserIDs[7]: {"Movies", "Music", "Design"},          // Divya
	}

	for userID, interests := range userInterests {
		for _, interestName := range interests {
			id, ok := interestMap[interestName]
			if !ok {
				continue // skip if interest doesn't exist in DB
			}
			h.db.ExecContext(ctx, `
				INSERT INTO user_interests (user_id, interest_id) VALUES ($1, $2)
				ON CONFLICT DO NOTHING
			`, userID, id)
		}
	}
}

func (h *SeedHandler) seedEnrollments(ctx context.Context) {
	enrollments := []struct{ userID, eventID, status string }{
		{seedUserIDs[0], seedEventIDs[0], "going"},
		{seedUserIDs[0], seedEventIDs[1], "interested"},
		{seedUserIDs[1], seedEventIDs[0], "going"},
		{seedUserIDs[1], seedEventIDs[1], "going"},
		{seedUserIDs[2], seedEventIDs[2], "going"},
		{seedUserIDs[3], seedEventIDs[3], "going"},
		{seedUserIDs[4], seedEventIDs[0], "interested"},
		{seedUserIDs[4], seedEventIDs[1], "going"},
		{seedUserIDs[5], seedEventIDs[4], "going"},
		{seedUserIDs[6], seedEventIDs[0], "going"},
		{seedUserIDs[7], seedEventIDs[2], "interested"},
		// Adding more enrollments so events have more users
		{seedUserIDs[2], seedEventIDs[1], "going"},
		{seedUserIDs[3], seedEventIDs[1], "going"},
		{seedUserIDs[5], seedEventIDs[1], "going"},
		{seedUserIDs[6], seedEventIDs[1], "interested"},
		{seedUserIDs[7], seedEventIDs[1], "going"},
	}
	for _, e := range enrollments {
		h.db.ExecContext(context.Background(), `
			INSERT INTO user_events (user_id, event_id, status) VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING
		`, e.userID, e.eventID, e.status)
	}
}

func (h *SeedHandler) seedGroups(ctx context.Context) {
	type seedGroup struct {
		id, eventID, name, description, createdBy, meetingPoint, departureDate string
	}

	groups := []seedGroup{
		{seedGroupIDs[0], seedEventIDs[1], "Delhi Hackers Travel", "Traveling from New Delhi to BITS Pilani together!", seedUserIDs[1], "NDLS Station", "2026-05-19"},
		{seedGroupIDs[1], seedEventIDs[1], "Mumbai to Pilani Squad", "Taking the flight from Mumbai to Jaipur then a cab.", seedUserIDs[0], "Mumbai Airport", "2026-05-20"},
		{seedGroupIDs[2], seedEventIDs[0], "TechFest Train Group", "Catching the express train to Mumbai.", seedUserIDs[4], "Chennai Central", "2026-06-10"},
	}

	for _, g := range groups {
		h.db.ExecContext(ctx, `
			INSERT INTO travel_groups (id, event_id, name, description, created_by, max_members, departure_date, meeting_point, requires_approval)
			VALUES ($1, $2, $3, $4, $5, 4, $6, $7, false)
			ON CONFLICT (id) DO NOTHING
		`, g.id, g.eventID, g.name, g.description, g.createdBy, g.departureDate, g.meetingPoint)

		// Auto-join creator (no status column — group_members only has group_id, user_id, joined_at)
		h.db.ExecContext(ctx, `INSERT INTO group_members (group_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, g.id, g.createdBy)
	}

	// Add extra members to groups
	h.db.ExecContext(ctx, `INSERT INTO group_members (group_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, seedGroupIDs[0], seedUserIDs[3])
	h.db.ExecContext(ctx, `INSERT INTO group_members (group_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, seedGroupIDs[1], seedUserIDs[2])
	h.db.ExecContext(ctx, `INSERT INTO group_members (group_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, seedGroupIDs[2], seedUserIDs[6])
}
