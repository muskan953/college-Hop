package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/events"
	"github.com/muskan953/college-Hop/internal/server"
)

// --- Events Handler Tests ---

func TestListEvents_ReturnsApproved(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockEventsRepo := &MockEventsRepositoryFull{
		ListApprovedEventsFunc: func(ctx context.Context) ([]events.Event, error) {
			return []events.Event{
				{ID: "evt-1", Name: "TechFest 2026", Venue: "NIT Warangal", Status: "approved"},
				{ID: "evt-2", Name: "HackNITW", Venue: "NIT Warangal", Status: "approved"},
			}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		mockEventsRepo, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/events", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /events: got status %d, want %d", rr.Code, http.StatusOK)
	}

	var result []events.Event
	if err := json.NewDecoder(rr.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if len(result) != 2 {
		t.Errorf("expected 2 events, got %d", len(result))
	}
}

func TestListEvents_EmptyList(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockEventsRepo := &MockEventsRepositoryFull{
		ListApprovedEventsFunc: func(ctx context.Context) ([]events.Event, error) {
			return nil, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		mockEventsRepo, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/events", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /events (empty): got status %d, want %d", rr.Code, http.StatusOK)
	}

	var result []events.Event
	json.NewDecoder(rr.Body).Decode(&result)
	if len(result) != 0 {
		t.Errorf("expected empty list, got %d events", len(result))
	}
}

func TestCreateEvent_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{
		"name":       "TechFest",
		"start_date": "2026-03-15",
		"venue":      "NIT Warangal",
		"organizer":  "CSE Dept",
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/events", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	// Should fail without auth token
	if rr.Code == http.StatusCreated {
		t.Error("POST /events should require authentication")
	}
}

func TestCreateEvent_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockEventsRepo := &MockEventsRepositoryFull{
		CreateEventFunc: func(ctx context.Context, event *events.Event) error {
			event.ID = "new-evt-id"
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		mockEventsRepo, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{
		"name":       "TechFest 2026",
		"start_date": "2026-03-15",
		"venue":      "NIT Warangal",
		"organizer":  "CSE Dept",
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/events", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("POST /events: got status %d, want %d. Body: %s", rr.Code, http.StatusCreated, rr.Body.String())
	}

	var result events.Event
	json.NewDecoder(rr.Body).Decode(&result)
	if result.Status != "pending" {
		t.Errorf("new event should have status 'pending', got '%s'", result.Status)
	}
}

func TestCreateEvent_ValidationFails(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepositoryFull{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	// Missing required fields
	payload := map[string]string{"name": "TechFest"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/events", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /events with missing fields: got %d, want %d", rr.Code, http.StatusBadRequest)
	}
}

func TestSetUserEvent_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"event_id": "evt-1"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("PUT", "/me/event", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("PUT /me/event without auth: got %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

// MockEventsRepositoryFull allows overriding individual methods
type MockEventsRepositoryFull struct {
	CreateEventFunc        func(ctx context.Context, event *events.Event) error
	ListApprovedEventsFunc func(ctx context.Context) ([]events.Event, error)
	ListPendingEventsFunc  func(ctx context.Context) ([]events.Event, error)
	UpdateEventStatusFunc  func(ctx context.Context, eventID string, status string) error
	GetEventFunc           func(ctx context.Context, eventID string) (*events.Event, error)
	SetUserEventFunc       func(ctx context.Context, userID, eventID, status string) error
	GetUserEventFunc       func(ctx context.Context, userID string) (*events.UserEvent, error)
}

func (m *MockEventsRepositoryFull) CreateEvent(ctx context.Context, event *events.Event) error {
	if m.CreateEventFunc != nil {
		return m.CreateEventFunc(ctx, event)
	}
	return nil
}
func (m *MockEventsRepositoryFull) ListApprovedEvents(ctx context.Context) ([]events.Event, error) {
	if m.ListApprovedEventsFunc != nil {
		return m.ListApprovedEventsFunc(ctx)
	}
	return []events.Event{}, nil
}
func (m *MockEventsRepositoryFull) ListPendingEvents(ctx context.Context) ([]events.Event, error) {
	if m.ListPendingEventsFunc != nil {
		return m.ListPendingEventsFunc(ctx)
	}
	return []events.Event{}, nil
}
func (m *MockEventsRepositoryFull) UpdateEventStatus(ctx context.Context, eventID string, status string) error {
	if m.UpdateEventStatusFunc != nil {
		return m.UpdateEventStatusFunc(ctx, eventID, status)
	}
	return nil
}
func (m *MockEventsRepositoryFull) GetEvent(ctx context.Context, eventID string) (*events.Event, error) {
	if m.GetEventFunc != nil {
		return m.GetEventFunc(ctx, eventID)
	}
	return &events.Event{Status: "approved"}, nil
}
func (m *MockEventsRepositoryFull) SetUserEvent(ctx context.Context, userID, eventID, status string) error {
	if m.SetUserEventFunc != nil {
		return m.SetUserEventFunc(ctx, userID, eventID, status)
	}
	return nil
}
func (m *MockEventsRepositoryFull) GetUserEvent(ctx context.Context, userID string) (*events.UserEvent, error) {
	if m.GetUserEventFunc != nil {
		return m.GetUserEventFunc(ctx, userID)
	}
	return &events.UserEvent{}, nil
}
