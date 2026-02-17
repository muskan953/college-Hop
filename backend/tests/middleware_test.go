package tests

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
)

// TestMiddlewareValidToken verifies that valid tokens inject the correct UserContext.
func TestMiddlewareValidToken(t *testing.T) {
	t.Setenv("JWT_SECRET", "test-secret")

	token, _ := auth.GenerateToken("user-123", "student@nitw.ac.in")

	handler := auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, ok := auth.UserFromContext(r.Context())
		if !ok {
			t.Fatal("expected user in context")
		}
		json.NewEncoder(w).Encode(map[string]string{
			"id":    user.ID,
			"email": user.Email,
		})
	}))

	req := httptest.NewRequest("GET", "/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}

	var body map[string]string
	json.NewDecoder(rr.Body).Decode(&body)

	if body["id"] != "user-123" {
		t.Errorf("expected user ID 'user-123', got '%s'", body["id"])
	}
	if body["email"] != "student@nitw.ac.in" {
		t.Errorf("expected email 'student@nitw.ac.in', got '%s'", body["email"])
	}
}

// TestMiddlewareMissingHeader verifies 401 when Authorization header is missing.
func TestMiddlewareMissingHeader(t *testing.T) {
	handler := auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called")
	}))

	req := httptest.NewRequest("GET", "/me", nil)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rr.Code)
	}
}

// TestMiddlewareMalformedHeader verifies 401 when header format is wrong.
func TestMiddlewareMalformedHeader(t *testing.T) {
	handler := auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called")
	}))

	tests := []struct {
		name   string
		header string
	}{
		{"No Bearer prefix", "token-without-bearer"},
		{"Basic instead of Bearer", "Basic some-token"},
		{"Empty Bearer", "Bearer "},
		{"Three parts", "Bearer token extra"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/me", nil)
			req.Header.Set("Authorization", tc.header)
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if rr.Code != http.StatusUnauthorized {
				t.Fatalf("expected 401, got %d", rr.Code)
			}
		})
	}
}

// TestMiddlewareExpiredToken verifies 401 for expired/invalid tokens.
func TestMiddlewareExpiredToken(t *testing.T) {
	t.Setenv("JWT_SECRET", "test-secret")

	handler := auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called")
	}))

	req := httptest.NewRequest("GET", "/me", nil)
	req.Header.Set("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxMDAwMDAwMDAwfQ.invalid")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rr.Code)
	}
}
