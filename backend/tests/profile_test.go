package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
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

func TestProfileUpdateValidation(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, mockStore, "./uploads")
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")

	tests := []struct {
		name    string
		payload map[string]interface{}
		want    int
	}{
		{
			name: "too long full name",
			payload: map[string]interface{}{
				"full_name":    strings.Repeat("a", 51),
				"college_name": "NITW",
				"major":        "CS",
				"roll_number":  "123",
			},
			want: http.StatusBadRequest,
		},
		{
			name: "too long bio",
			payload: map[string]interface{}{
				"full_name":    "Test",
				"college_name": "NITW",
				"major":        "CS",
				"roll_number":  "123",
				"bio":          strings.Repeat("a", 501),
			},
			want: http.StatusBadRequest,
		},
		{
			name: "missing required field",
			payload: map[string]interface{}{
				"full_name": "Test",
				// college_name missing
				"major":       "CS",
				"roll_number": "123",
			},
			want: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.payload)
			req, _ := http.NewRequest("PUT", "/me", bytes.NewBuffer(body))
			req.Header.Set("Authorization", "Bearer "+token)
			rr := httptest.NewRecorder()

			router.ServeHTTP(rr, req)

			if status := rr.Code; status != tt.want {
				t.Errorf("%s: handler returned wrong status code: got %v want %v", tt.name, status, tt.want)
			}
		})
	}
}
