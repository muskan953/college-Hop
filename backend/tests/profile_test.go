package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/internal/server"
)

func TestProfileGetMe(t *testing.T) {
	// Set JWT secret for test environment
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{
		GetProfileFunc: func(ctx context.Context, userID string) (*profile.ProfileResponse, error) {
			return &profile.ProfileResponse{
				FullName:    "Test User",
				CollegeName: "NIT Warangal",
				Major:       "Computer Science",
			}, nil
		},
	}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, mockStore, "./uploads")

	// Generate token (this uses the JWT_SECRET from env)
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")

	req, _ := http.NewRequest("GET", "/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var resp profile.ProfileResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Errorf("failed to decode response: %v", err)
	}

	if resp.FullName != "Test User" {
		t.Errorf("unexpected body: got %v want %v", resp.FullName, "Test User")
	}
}

func TestProfileUpdateMe(t *testing.T) {
	// Set JWT secret for test environment
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{
		UpsertProfileFunc: func(ctx context.Context, userID string, req profile.UpdateProfileRequest) error {
			return nil
		},
	}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, mockStore, "./uploads")

	// Generate token
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")

	payload := map[string]interface{}{
		"full_name":    "Updated User",
		"college_name": "NIT Warangal",
		"major":        "Computer Science",
		"roll_number":  "123456",
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("PUT", "/me", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}
