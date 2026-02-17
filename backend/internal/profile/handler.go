package profile

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strings"

	"github.com/muskan953/college-Hop/internal/auth"
)

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

// IsValidUploadURL checks that the URL is a valid absolute URL.
func IsValidUploadURL(rawURL string) bool {
	if rawURL == "" {
		return true // optional field
	}
	u, err := url.ParseRequestURI(rawURL)
	if err != nil {
		return false
	}
	return (u.Scheme == "http" || u.Scheme == "https") && u.Host != ""
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

	// Trim whitespace
	req.FullName = strings.TrimSpace(req.FullName)
	req.CollegeName = strings.TrimSpace(req.CollegeName)
	req.Major = strings.TrimSpace(req.Major)
	req.RollNumber = strings.TrimSpace(req.RollNumber)
	req.Bio = strings.TrimSpace(req.Bio)

	// Validation
	if req.FullName == "" || req.CollegeName == "" || req.Major == "" || req.RollNumber == "" {
		http.Error(w, "missing required fields (full_name, college_name, major, roll_number)", http.StatusBadRequest)
		return
	}

	if len(req.FullName) > 50 {
		http.Error(w, "full_name too long (max 50 chars)", http.StatusBadRequest)
		return
	}
	if len(req.CollegeName) > 100 {
		http.Error(w, "college_name too long (max 100 chars)", http.StatusBadRequest)
		return
	}
	if len(req.Major) > 50 {
		http.Error(w, "major too long (max 50 chars)", http.StatusBadRequest)
		return
	}
	if len(req.RollNumber) > 20 {
		http.Error(w, "roll_number too long (max 20 chars)", http.StatusBadRequest)
		return
	}
	if len(req.Bio) > 500 {
		http.Error(w, "bio too long (max 500 chars)", http.StatusBadRequest)
		return
	}

	// Validate URL fields
	if !IsValidUploadURL(req.ProfilePhotoURL) {
		http.Error(w, "invalid profile_photo_url: must be a valid URL", http.StatusBadRequest)
		return
	}
	if !IsValidUploadURL(req.IDCardURL) {
		http.Error(w, "invalid college_id_card_url: must be a valid URL", http.StatusBadRequest)
		return
	}

	// Validate file type via URL extension
	if req.ProfilePhotoURL != "" {
		ext := strings.ToLower(req.ProfilePhotoURL[strings.LastIndex(req.ProfilePhotoURL, "."):])
		if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
			http.Error(w, "profile_photo_url must point to an image (.jpg, .png, .webp)", http.StatusBadRequest)
			return
		}
	}
	if req.IDCardURL != "" {
		ext := strings.ToLower(req.IDCardURL[strings.LastIndex(req.IDCardURL, "."):])
		if ext != ".pdf" {
			http.Error(w, "college_id_card_url must point to a PDF (.pdf)", http.StatusBadRequest)
			return
		}
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
