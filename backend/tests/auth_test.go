package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/server"
)

func TestAuthSignup(t *testing.T) {
	mockAuthRepo := &MockAuthRepository{
		CanRequestOTPFunc: func(ctx context.Context, email string) (bool, error) {
			return true, nil
		},
		SaveOTPFunc: func(ctx context.Context, email string, otpHash string, expiresAt time.Time) error {
			return nil
		},
	}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, mockStore, "./uploads")

	payload := map[string]string{"email": "student@nitw.ac.in"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/signup", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}

func TestAuthVerify(t *testing.T) {
	mockAuthRepo := &MockAuthRepository{
		VerifyOTPFunc: func(ctx context.Context, email string, otpHash string) error {
			return nil
		},
		GetOrCreateUserFunc: func(ctx context.Context, email string) (string, error) {
			return "test-user-id", nil
		},
	}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, mockStore, "./uploads")

	payload := map[string]string{"email": "student@nitw.ac.in", "otp": "123456"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/verify", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()

	// Setting JWT_SECRET for test environment
	t.Setenv("JWT_SECRET", "testsecret")

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var resp auth.VerifyResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Errorf("failed to decode response: %v", err)
	}

	if resp.Token == "" {
		t.Error("expected token in response")
	}
}
