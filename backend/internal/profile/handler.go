package profile

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strings"

	"github.com/muskan953/college-Hop/internal/auth"
)

type Handler struct {
	repo     Repository
	authRepo auth.Repository
}

func NewHandler(repo Repository, authRepo auth.Repository) *Handler {
	return &Handler{repo: repo, authRepo: authRepo}
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
	req.AlternateEmail = strings.TrimSpace(req.AlternateEmail)

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

func (h *Handler) UpdatePreferences(w http.ResponseWriter, r *http.Request) {

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req UpdatePreferencesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// Validate profile_visibility
	req.ProfileVisibility = strings.TrimSpace(req.ProfileVisibility)
	if req.ProfileVisibility == "" {
		req.ProfileVisibility = "public"
	}
	allowed := map[string]bool{"public": true, "connections": true, "private": true}
	if !allowed[req.ProfileVisibility] {
		http.Error(w, "profile_visibility must be one of: public, connections, private", http.StatusBadRequest)
		return
	}

	if err := h.repo.UpsertPreferences(r.Context(), user.ID, req); err != nil {
		http.Error(w, "failed to update preferences", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("preferences updated"))
}

func (h *Handler) GetPreferences(w http.ResponseWriter, r *http.Request) {

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	prefs, err := h.repo.GetPreferences(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get preferences", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(prefs)
}

// GetPublicProfile handles GET /users/{id} — requires auth (app-only access).
func (h *Handler) GetPublicProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract user ID from path: /users/{id}
	path := strings.TrimPrefix(r.URL.Path, "/users/")
	userID := strings.Trim(path, "/")
	if userID == "" {
		http.Error(w, "missing user id", http.StatusBadRequest)
		return
	}

	profile, err := h.repo.GetPublicProfile(r.Context(), userID)
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profile)
}

// ConnectUser handles POST /users/{id}/connect — creates a connection between
// the authenticated user and the target user.
func (h *Handler) ConnectUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract target user ID: /users/{id}/connect
	path := strings.TrimPrefix(r.URL.Path, "/users/")
	path = strings.TrimSuffix(path, "/connect")
	targetID := strings.Trim(path, "/")
	if targetID == "" {
		http.Error(w, "missing user id", http.StatusBadRequest)
		return
	}

	if targetID == user.ID {
		http.Error(w, "cannot connect with yourself", http.StatusBadRequest)
		return
	}

	err := h.repo.CreateConnection(r.Context(), user.ID, targetID)
	if err != nil {
		// Duplicate connections are silently ignored by the upsert
		http.Error(w, "failed to create connection", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "connected"})
}

// RequestAlternateEmailOTP handles POST /me/alternate-email/request-otp.
// Sends an OTP to the proposed alternate email so we can verify ownership.
func (h *Handler) RequestAlternateEmailOTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	_, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		Email string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	req.Email = strings.TrimSpace(req.Email)
	if req.Email == "" || !strings.Contains(req.Email, "@") {
		http.Error(w, "invalid email address", http.StatusBadRequest)
		return
	}

	// Rate-limit
	allowed, err := h.authRepo.CanRequestOTP(r.Context(), req.Email)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	if !allowed {
		http.Error(w, "please wait before requesting another OTP", http.StatusTooManyRequests)
		return
	}

	otp, err := auth.GenerateOTP()
	if err != nil {
		http.Error(w, "failed to generate OTP", http.StatusInternalServerError)
		return
	}

	otpHash := auth.HashOTP(otp)
	expiresAt := auth.OTPExpiry()

	if err := h.authRepo.SaveOTP(r.Context(), req.Email, otpHash, expiresAt); err != nil {
		http.Error(w, "failed to save OTP", http.StatusInternalServerError)
		return
	}

	// TEMP: log OTP (remove in production)
	log.Printf("Alternate email OTP for %s: %s", req.Email, otp)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "OTP sent"})
}

// VerifyAlternateEmail handles POST /me/alternate-email/verify.
// Verifies the OTP and saves the alternate email to the user's profile.
func (h *Handler) VerifyAlternateEmail(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		Email string `json:"email"`
		OTP   string `json:"otp"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	req.Email = strings.TrimSpace(req.Email)
	if req.Email == "" || req.OTP == "" {
		http.Error(w, "email and otp are required", http.StatusBadRequest)
		return
	}

	otpHash := auth.HashOTP(req.OTP)
	if err := h.authRepo.VerifyOTP(r.Context(), req.Email, otpHash); err != nil {
		http.Error(w, "invalid or expired OTP", http.StatusUnauthorized)
		return
	}

	// OTP verified — persist the alternate email
	if err := h.repo.SaveAlternateEmail(r.Context(), user.ID, req.Email); err != nil {
		http.Error(w, "failed to save alternate email", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "alternate email verified and saved"})
}
