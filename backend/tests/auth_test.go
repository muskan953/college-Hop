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

	router := server.NewRouter(mockAuthRepo, nil, mockProfileRepo, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, mockStore, "./uploads")

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

	router := server.NewRouter(mockAuthRepo, nil, mockProfileRepo, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, mockStore, "./uploads")

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

	if resp.AccessToken == "" {
		t.Error("expected access_token in response")
	}

	if resp.RefreshToken == "" {
		t.Error("expected refresh_token in response")
	}
}

func TestAuthRefresh(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	// 1. Setup mock repo
	storedUserID := "test-user-id"
	storedEmail := "student@nitw.ac.in"

	// Create a real refresh token to test with
	refreshToken, _ := auth.GenerateRefreshToken(storedUserID, storedEmail)
	tokenHash := auth.HashOTP(refreshToken)

	mockAuthRepo := &MockAuthRepository{
		GetRefreshTokenFunc: func(ctx context.Context, hash string) (string, time.Time, error) {
			if hash == tokenHash {
				return storedUserID, time.Now().Add(time.Hour), nil
			}
			return "", time.Time{}, auth.ErrRefreshTokenNotFound
		},
		DeleteRefreshTokenFunc: func(ctx context.Context, hash string) error {
			return nil
		},
		SaveRefreshTokenFunc: func(ctx context.Context, userID string, hash string, expiresAt time.Time) error {
			return nil
		},
	}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, nil, mockProfileRepo, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, mockStore, "./uploads")

	// 2. Refresh request
	payload := auth.RefreshRequest{RefreshToken: refreshToken}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/refresh", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	// 3. Verify response
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var resp auth.RefreshResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Errorf("failed to decode response: %v", err)
	}

	if resp.AccessToken == "" || resp.RefreshToken == "" {
		t.Error("expected new access and refresh tokens")
	}

	if resp.RefreshToken == refreshToken {
		t.Error("expected refresh token rotation (different token)")
	}
}

func TestAuthLogout(t *testing.T) {
	mockAuthRepo := &MockAuthRepository{
		DeleteRefreshTokenFunc: func(ctx context.Context, hash string) error {
			return nil
		},
	}
	mockProfileRepo := &MockProfileRepository{}
	mockStore := &MockFileStorage{}

	router := server.NewRouter(mockAuthRepo, nil, mockProfileRepo, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, mockStore, "./uploads")

	payload := auth.RefreshRequest{RefreshToken: "some-token"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/logout", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()

	router.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}

// TestAuthSignup_OTPRateLimit verifies that when CanRequestOTP returns false
// the handler responds with 429 Too Many Requests.
func TestAuthSignup_OTPRateLimit(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")
	mockAuthRepo := &MockAuthRepository{
		CanRequestOTPFunc: func(ctx context.Context, email string) (bool, error) {
			return false, nil // rate-limited
		},
	}
	router := server.NewRouter(mockAuthRepo, nil, &MockProfileRepository{}, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, &MockFileStorage{}, "./uploads")

	payload := map[string]string{"email": "student@nitw.ac.in"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/signup", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusTooManyRequests {
		t.Errorf("signup rate-limited: got %d, want 429", rr.Code)
	}
}

// TestAuthVerify_BlockedUser verifies that a user whose account status is "blocked"
// is rejected with 403 on any protected endpoint after they have a valid token.
func TestAuthVerify_BlockedUser(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")
	mockAuthRepo := &MockAuthRepository{
		GetUserStatusFunc: func(ctx context.Context, userID string) (string, error) {
			return "blocked", nil
		},
	}
	router := server.NewRouter(mockAuthRepo, nil, &MockProfileRepository{}, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, &MockFileStorage{}, "./uploads")

	token, _ := auth.GenerateToken("blocked-user-id", "student@nitw.ac.in")
	req, _ := http.NewRequest("GET", "/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("blocked user accessing /me: got %d, want 403", rr.Code)
	}
}

// TestAuthRefresh_InvalidToken verifies that a garbage refresh token returns 401.
func TestAuthRefresh_InvalidToken(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")
	router := server.NewRouter(&MockAuthRepository{}, nil, &MockProfileRepository{}, &MockAdminRepository{}, &MockEventsRepository{}, &MockGroupsRepository{}, nil, nil, &MockFileStorage{}, "./uploads")

	payload := auth.RefreshRequest{RefreshToken: "this-is-not-a-valid-token"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/auth/refresh", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("refresh with invalid token: got %d, want 401", rr.Code)
	}
}
