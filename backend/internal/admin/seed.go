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

	// Delete in reverse dependency order
	h.db.ExecContext(ctx, `DELETE FROM user_events WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM user_events WHERE event_id IN (`+eventIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM user_interests WHERE user_id IN (`+userIDList+`)`)
	h.db.ExecContext(ctx, `DELETE FROM group_members WHERE user_id IN (`+userIDList+`)`)
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
	interests := []struct {
		id   int
		name string
	}{
		{201, "Artificial Intelligence"}, {202, "Machine Learning"}, {203, "Web Development"},
		{204, "Mobile Apps"}, {205, "Robotics"}, {206, "Data Science"},
		{207, "Blockchain"}, {208, "UI/UX Design"}, {209, "Startups"}, {210, "Open Source"},
	}
	for _, i := range interests {
		h.db.ExecContext(ctx, `INSERT INTO interests (id, name) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING`, i.id, i.name)
	}

	assignments := []struct {
		userID     string
		interestID int
	}{
		{seedUserIDs[0], 201}, {seedUserIDs[0], 202}, {seedUserIDs[0], 205},
		{seedUserIDs[1], 203}, {seedUserIDs[1], 204}, {seedUserIDs[1], 210},
		{seedUserIDs[2], 201}, {seedUserIDs[2], 202}, {seedUserIDs[2], 206},
		{seedUserIDs[3], 209}, {seedUserIDs[3], 203},
		{seedUserIDs[4], 203}, {seedUserIDs[4], 204}, {seedUserIDs[4], 210},
		{seedUserIDs[5], 208}, {seedUserIDs[5], 209},
		{seedUserIDs[6], 205}, {seedUserIDs[6], 210},
		{seedUserIDs[7], 201}, {seedUserIDs[7], 207},
	}
	for _, a := range assignments {
		h.db.ExecContext(ctx, `INSERT INTO user_interests (user_id, interest_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, a.userID, a.interestID)
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
	}
	for _, e := range enrollments {
		h.db.ExecContext(context.Background(), `
			INSERT INTO user_events (user_id, event_id, status) VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING
		`, e.userID, e.eventID, e.status)
	}
}
