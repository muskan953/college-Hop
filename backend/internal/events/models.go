package events

import "time"

// Event represents a hackathon/conference/meetup
type Event struct {
	ID              string     `json:"id"`
	Name            string     `json:"name"`
	Category        string     `json:"category,omitempty"`
	Venue           string     `json:"venue"`
	Organizer       string     `json:"organizer"`
	StartDate       time.Time  `json:"start_date"`
	EndDate         *time.Time `json:"end_date,omitempty"`
	TimeDescription string     `json:"time_description,omitempty"`
	EventLink       string     `json:"event_link,omitempty"`
	BrochureURL     string     `json:"brochure_url,omitempty"`
	TicketLink      string     `json:"ticket_link,omitempty"`
	SubmittedBy     string     `json:"submitted_by,omitempty"`
	Status          string     `json:"status"`
	CreatedAt       time.Time  `json:"created_at"`
}

// CreateEventRequest is the payload for POST /events
type CreateEventRequest struct {
	Name            string `json:"name"`
	Category        string `json:"category"`
	Venue           string `json:"venue"`
	Organizer       string `json:"organizer"`
	StartDate       string `json:"start_date"` // ISO 8601: YYYY-MM-DD
	EndDate         string `json:"end_date"`   // ISO 8601: YYYY-MM-DD (optional)
	TimeDescription string `json:"time_description"`
	EventLink       string `json:"event_link"`
	BrochureURL     string `json:"brochure_url"`
	TicketLink      string `json:"ticket_link"` // optional
}

// UserEvent tracks which event a user is attending
type UserEvent struct {
	UserID  string `json:"user_id"`
	EventID string `json:"event_id"`
	Status  string `json:"status"` // interested, going, looking_for_group
}

// SetEventRequest is the payload for PUT /me/event
type SetEventRequest struct {
	EventID string `json:"event_id"`
	Status  string `json:"status"`
}
