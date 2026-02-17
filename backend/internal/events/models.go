package events

import "time"

// Event represents a hackathon/conference/meetup
type Event struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Date        time.Time `json:"date"`
	Location    string    `json:"location"`
	Organizer   string    `json:"organizer"`
	URL         string    `json:"url,omitempty"`
	SubmittedBy string    `json:"submitted_by,omitempty"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
}

// CreateEventRequest is the payload for POST /events
type CreateEventRequest struct {
	Name      string `json:"name"`
	Date      string `json:"date"` // ISO 8601
	Location  string `json:"location"`
	Organizer string `json:"organizer"`
	URL       string `json:"url"`
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
