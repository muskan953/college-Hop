package profile

import (
	"encoding/json"
	"net/http"

	"github.com/muskan953/college-Hop/internal/auth"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) UpdateMe(w http.ResponseWriter, r *http.Request) {

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// minimal validation
	if req.FullName == "" || req.CollegeName == "" || req.Major == "" || req.RollNumber == "" {
		http.Error(w, "missing required fields", http.StatusBadRequest)
		return
	}

	err := h.repo.UpsertProfile(r.Context(), user.ID, req)
	if err != nil {
		http.Error(w, "failed to update profile", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("profile updated"))
}

func (h *Handler) GetMe(w http.ResponseWriter, r *http.Request) {

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	profile, err := h.repo.GetProfile(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "profile not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profile)
}
