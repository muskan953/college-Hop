package admin

import (
	"encoding/json"
	"net/http"
	"os"
	"strings"
)

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

// AdminAuth is a simple middleware that checks for the X-Admin-Secret header.
func AdminAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		secret := os.Getenv("ADMIN_SECRET")
		if secret == "" {
			http.Error(w, "admin access not configured", http.StatusServiceUnavailable)
			return
		}

		provided := r.Header.Get("X-Admin-Secret")
		if provided == "" || provided != secret {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// ListPendingUsers returns all users with status = 'pending'.
func (h *Handler) ListPendingUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	users, err := h.repo.ListUsersByStatus(r.Context(), "pending")
	if err != nil {
		http.Error(w, "failed to list users", http.StatusInternalServerError)
		return
	}

	if users == nil {
		users = []UserRow{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// extractUserID extracts the user ID from a URL like /admin/users/{id}/verify
func extractUserID(path string) string {
	// Expected: /admin/users/{id}/verify or /admin/users/{id}/block
	parts := strings.Split(strings.TrimPrefix(path, "/"), "/")
	if len(parts) >= 3 {
		return parts[2] // admin / users / {id} / action
	}
	return ""
}

// VerifyUser sets a user's status to 'verified'.
func (h *Handler) VerifyUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := extractUserID(r.URL.Path)
	if userID == "" {
		http.Error(w, "missing user ID", http.StatusBadRequest)
		return
	}

	if err := h.repo.UpdateUserStatus(r.Context(), userID, "verified"); err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "user verified", "user_id": userID})
}

// BlockUser sets a user's status to 'blocked'.
func (h *Handler) BlockUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := extractUserID(r.URL.Path)
	if userID == "" {
		http.Error(w, "missing user ID", http.StatusBadRequest)
		return
	}

	if err := h.repo.UpdateUserStatus(r.Context(), userID, "blocked"); err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "user blocked", "user_id": userID})
}
