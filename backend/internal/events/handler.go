package events

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/muskan953/college-Hop/internal/auth"
)

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

// POST /events — Submit a new event (any authenticated user)
func (h *Handler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// Trim whitespace
	req.Name = strings.TrimSpace(req.Name)
	req.Venue = strings.TrimSpace(req.Venue)
	req.Organizer = strings.TrimSpace(req.Organizer)
	req.Category = strings.TrimSpace(req.Category)
	req.TimeDescription = strings.TrimSpace(req.TimeDescription)
	req.EventLink = strings.TrimSpace(req.EventLink)
	req.BrochureURL = strings.TrimSpace(req.BrochureURL)
	req.TicketLink = strings.TrimSpace(req.TicketLink)

	// Required field validation
	if req.Name == "" || req.Venue == "" || req.Organizer == "" || req.StartDate == "" {
		http.Error(w, "missing required fields (name, start_date, venue, organizer)", http.StatusBadRequest)
		return
	}

	startDate, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		http.Error(w, "invalid start_date format, use YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	event := &Event{
		Name:            req.Name,
		Category:        req.Category,
		Venue:           req.Venue,
		Organizer:       req.Organizer,
		StartDate:       startDate,
		TimeDescription: req.TimeDescription,
		EventLink:       req.EventLink,
		BrochureURL:     req.BrochureURL,
		TicketLink:      req.TicketLink,
		SubmittedBy:     user.ID,
		Status:          "pending",
	}

	// Optional end date
	if req.EndDate != "" {
		endDate, err := time.Parse("2006-01-02", req.EndDate)
		if err != nil {
			http.Error(w, "invalid end_date format, use YYYY-MM-DD", http.StatusBadRequest)
			return
		}
		if endDate.Before(startDate) {
			http.Error(w, "end_date must be on or after start_date", http.StatusBadRequest)
			return
		}
		event.EndDate = &endDate
	}

	if err := h.repo.CreateEvent(r.Context(), event); err != nil {
		http.Error(w, "failed to create event", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(event)
}

// GET /events — List all approved events
func (h *Handler) ListEvents(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	events, err := h.repo.ListApprovedEvents(r.Context())
	if err != nil {
		http.Error(w, "failed to fetch events", http.StatusInternalServerError)
		return
	}

	if events == nil {
		events = []Event{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(events)
}

// GET /admin/events/pending — List pending events (admin only)
func (h *Handler) ListPendingEvents(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	events, err := h.repo.ListPendingEvents(r.Context())
	if err != nil {
		http.Error(w, "failed to fetch pending events", http.StatusInternalServerError)
		return
	}

	if events == nil {
		events = []Event{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(events)
}

// POST /admin/events/{id}/approve
func (h *Handler) ApproveEvent(w http.ResponseWriter, r *http.Request) {
	h.updateStatus(w, r, "approved")
}

// POST /admin/events/{id}/reject
func (h *Handler) RejectEvent(w http.ResponseWriter, r *http.Request) {
	h.updateStatus(w, r, "rejected")
}

func (h *Handler) updateStatus(w http.ResponseWriter, r *http.Request, status string) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract event ID from URL: /admin/events/{id}/approve
	path := strings.TrimSuffix(r.URL.Path, "/"+status)
	parts := strings.Split(path, "/")
	if len(parts) < 4 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	eventID := parts[3] // /admin/events/{id}

	if err := h.repo.UpdateEventStatus(r.Context(), eventID, status); err != nil {
		http.Error(w, "failed to update event status", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "event " + status})
}

// PUT /me/event — Set the user's current target event
func (h *Handler) SetUserEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req SetEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.EventID == "" {
		http.Error(w, "event_id is required", http.StatusBadRequest)
		return
	}

	status := req.Status
	if status == "" {
		status = "interested"
	}

	// Verify the event exists and is approved
	event, err := h.repo.GetEvent(r.Context(), req.EventID)
	if err != nil {
		http.Error(w, "event not found", http.StatusNotFound)
		return
	}
	if event.Status != "approved" {
		http.Error(w, "event is not available", http.StatusBadRequest)
		return
	}

	if err := h.repo.SetUserEvent(r.Context(), user.ID, req.EventID, status); err != nil {
		http.Error(w, "failed to set event", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "event set"})
}

// GET /me/event — Get the user's current selected event
func (h *Handler) GetUserEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	ue, err := h.repo.GetUserEvent(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "no event selected", http.StatusNotFound)
		return
	}

	// Fetch full event details
	event, err := h.repo.GetEvent(r.Context(), ue.EventID)
	if err != nil {
		http.Error(w, "event not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"event":  event,
		"status": ue.Status,
	})
}
