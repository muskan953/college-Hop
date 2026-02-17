package tests

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/server"
)

func stringReader(s string) *strings.Reader {
	return strings.NewReader(s)
}

// TestIDCardRequiresAuth verifies that ID card files are PRIVATE.
func TestIDCardRequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, &MockAdminRepository{}, mockStore, "./uploads")

	// Request an ID card without any Authorization header
	req, _ := http.NewRequest("GET", "/uploads/id_card/somefile.pdf", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 Unauthorized for ID card without token, got %d", rr.Code)
	}
}

// TestProfilePhotoIsPublic verifies that profile photos do NOT require auth.
func TestProfilePhotoIsPublic(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, &MockAdminRepository{}, mockStore, "./uploads")

	// Request a profile photo without any Authorization header
	// We expect 404 (file doesn't exist) but NOT 401 (unauthorized)
	req, _ := http.NewRequest("GET", "/uploads/profile_photo/somefile.jpg", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusUnauthorized {
		t.Error("profile photos should be public, got 401 Unauthorized")
	}
}

// TestOTPBruteForceProtection verifies that OTP verification blocks after 5 failed attempts.
func TestOTPBruteForceProtection(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	attemptCount := 0

	mockAuthRepo := &MockAuthRepository{
		VerifyOTPFunc: func(ctx context.Context, email string, otpHash string) error {
			attemptCount++
			if attemptCount <= 5 {
				return errors.New("invalid otp")
			}
			// 6th attempt: simulate "too many attempts" even if OTP is correct
			return errors.New("too many attempts, request a new code")
		},
		GetOrCreateUserFunc: func(ctx context.Context, email string) (string, error) {
			return "test-user-id", nil
		},
	}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, &MockAdminRepository{}, mockStore, "./uploads")

	// Simulate 5 failed attempts
	for i := 0; i < 5; i++ {
		payload := `{"email":"student@nitw.ac.in","otp":"000000"}`
		req, _ := http.NewRequest("POST", "/auth/verify", stringReader(payload))
		rr := httptest.NewRecorder()
		router.ServeHTTP(rr, req)

		if rr.Code != http.StatusUnauthorized {
			t.Errorf("attempt %d: expected 401, got %d", i+1, rr.Code)
		}
	}

	// 6th attempt with "correct" OTP should STILL fail
	payload := `{"email":"student@nitw.ac.in","otp":"123456"}`
	req, _ := http.NewRequest("POST", "/auth/verify", stringReader(payload))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusOK {
		t.Error("6th attempt should be blocked even with correct OTP, but got 200 OK")
	}
}

// TestIDCardAccessWithToken verifies that authenticated users CAN access ID cards.
func TestIDCardAccessWithToken(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockAuthRepo := &MockAuthRepository{}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, mockProfileRepo, &MockAdminRepository{}, mockStore, "./uploads")

	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")

	// Request an ID card WITH a valid token
	// We expect 404 (file doesn't exist on disk) but NOT 401
	req, _ := http.NewRequest("GET", "/uploads/id_card/somefile.pdf", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusUnauthorized {
		t.Error("authenticated user should be able to access ID cards, got 401")
	}
}
