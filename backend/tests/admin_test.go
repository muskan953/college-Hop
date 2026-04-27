package tests

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/admin"
	"github.com/muskan953/college-Hop/internal/server"
)

func newAdminRouter(t *testing.T) http.Handler {
	t.Helper()
	t.Setenv("JWT_SECRET", "testsecret")
	t.Setenv("ADMIN_SECRET", "test-admin-secret")
	return server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		nil, nil, &MockFileStorage{}, "./uploads",
	)
}

// TestAdminListPending_NoSecret verifies that missing X-Admin-Secret returns 403.
func TestAdminListPending_NoSecret(t *testing.T) {
	router := newAdminRouter(t)
	req, _ := http.NewRequest("GET", "/admin/users/pending", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusForbidden {
		t.Errorf("GET /admin/users/pending without secret: got %d, want 403", rr.Code)
	}
}

// TestAdminListPending_Success verifies an authenticated admin can list pending users.
func TestAdminListPending_Success(t *testing.T) {
	mockAdminRepo := &MockAdminRepository{
		ListUsersByStatusFunc: func(ctx context.Context, status string) ([]admin.UserRow, error) {
			return []admin.UserRow{
				{UserID: "u1", Email: "a@nitw.ac.in", Status: "pending"},
				{UserID: "u2", Email: "b@nitw.ac.in", Status: "pending"},
			}, nil
		},
	}
	t.Setenv("JWT_SECRET", "testsecret")
	t.Setenv("ADMIN_SECRET", "test-admin-secret")
	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, mockAdminRepo,
		&MockEventsRepository{}, &MockGroupsRepository{},
		nil, nil, &MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/admin/users/pending", nil)
	req.Header.Set("X-Admin-Secret", "test-admin-secret")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /admin/users/pending: got %d, want 200", rr.Code)
	}
	var users []admin.UserRow
	json.NewDecoder(rr.Body).Decode(&users)
	if len(users) != 2 {
		t.Errorf("expected 2 users, got %d", len(users))
	}
}

// TestAdminVerifyUser_Success verifies the admin can approve a user.
func TestAdminVerifyUser_Success(t *testing.T) {
	verified := false
	mockAdminRepo := &MockAdminRepository{
		UpdateUserStatusFunc: func(ctx context.Context, userID string, status string) error {
			if userID == "u1" && status == "verified" {
				verified = true
			}
			return nil
		},
	}
	t.Setenv("JWT_SECRET", "testsecret")
	t.Setenv("ADMIN_SECRET", "test-admin-secret")
	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, mockAdminRepo,
		&MockEventsRepository{}, &MockGroupsRepository{},
		nil, nil, &MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/admin/users/u1/verify", nil)
	req.Header.Set("X-Admin-Secret", "test-admin-secret")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("POST /admin/users/{id}/verify: got %d, want 200. Body: %s", rr.Code, rr.Body.String())
	}
	if !verified {
		t.Error("expected UpdateUserStatus to be called with 'verified'")
	}
}

// TestAdminBlockUser_Success verifies the admin can block a user.
func TestAdminBlockUser_Success(t *testing.T) {
	blocked := false
	mockAdminRepo := &MockAdminRepository{
		UpdateUserStatusFunc: func(ctx context.Context, userID string, status string) error {
			if userID == "u1" && status == "blocked" {
				blocked = true
			}
			return nil
		},
	}
	t.Setenv("JWT_SECRET", "testsecret")
	t.Setenv("ADMIN_SECRET", "test-admin-secret")
	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, mockAdminRepo,
		&MockEventsRepository{}, &MockGroupsRepository{},
		nil, nil, &MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/admin/users/u1/block", nil)
	req.Header.Set("X-Admin-Secret", "test-admin-secret")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("POST /admin/users/{id}/block: got %d, want 200", rr.Code)
	}
	if !blocked {
		t.Error("expected UpdateUserStatus to be called with 'blocked'")
	}
}

// TestAdminApproveEvent_Success verifies the admin can approve a pending event.
func TestAdminApproveEvent_Success(t *testing.T) {
	router := newAdminRouter(t)
	req, _ := http.NewRequest("POST", "/admin/events/evt-1/approve", nil)
	req.Header.Set("X-Admin-Secret", "test-admin-secret")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /admin/events/{id}/approve: got %d, want 200. Body: %s", rr.Code, rr.Body.String())
	}
}
