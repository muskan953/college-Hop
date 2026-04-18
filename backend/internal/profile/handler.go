package profile

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strings"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/messages"
)

type Handler struct {
	repo     Repository
	authRepo auth.Repository
	msgRepo  messages.Repository
}

func NewHandler(repo Repository, authRepo auth.Repository, msgRepo messages.Repository) *Handler {
	return &Handler{repo: repo, authRepo: authRepo, msgRepo: msgRepo}
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

// ConnectUser handles POST /users/{id}/connect — creates a pending connection and request thread between
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

	// Parse initial message from body
	var req struct {
		Message string `json:"message"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		req.Message = ""
	}
	req.Message = strings.TrimSpace(req.Message)
	if req.Message == "" {
		http.Error(w, "message is required to send connection request", http.StatusBadRequest)
		return
	}

	// 1. Create a pending connection
	err := h.repo.CreateConnection(r.Context(), user.ID, targetID, "pending", &user.ID)
	if err != nil {
		http.Error(w, "failed to create connection request", http.StatusInternalServerError)
		return
	}

	// 2. Create the request thread
	thread, err := h.msgRepo.GetOrCreateDirectThread(r.Context(), user.ID, targetID, true)
	if err != nil {
		http.Error(w, "failed to create message thread", http.StatusInternalServerError)
		return
	}

	// 3. Insert the first message into the thread
	_, err = h.msgRepo.CreateMessage(r.Context(), thread.ID, user.ID, req.Message, nil, false)
	if err != nil {
		// Log error but don't fail the who request since the connection was created
		log.Printf("[ConnectUser] Failed to send initial message: %v", err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "connection request sent"})
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

func (h *Handler) GetConnections(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	conns, err := h.repo.GetConnections(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get connections", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(conns)
}

// BlockUser handles POST /users/{id}/block — blocks another user.
func (h *Handler) BlockUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract target user ID: /users/{id}/block
	path := strings.TrimPrefix(r.URL.Path, "/users/")
	path = strings.TrimSuffix(path, "/block")
	targetID := strings.Trim(path, "/")
	if targetID == "" {
		http.Error(w, "missing user id", http.StatusBadRequest)
		return
	}

	if targetID == user.ID {
		http.Error(w, "cannot block yourself", http.StatusBadRequest)
		return
	}

	if err := h.repo.BlockUser(r.Context(), user.ID, targetID); err != nil {
		http.Error(w, "failed to block user", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "user blocked"})
}

// UnblockUser handles POST /users/{id}/unblock — unblocks a previously blocked user.
func (h *Handler) UnblockUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract target user ID: /users/{id}/unblock
	path := strings.TrimPrefix(r.URL.Path, "/users/")
	path = strings.TrimSuffix(path, "/unblock")
	targetID := strings.Trim(path, "/")
	if targetID == "" {
		http.Error(w, "missing user id", http.StatusBadRequest)
		return
	}

	if err := h.repo.UnblockUser(r.Context(), user.ID, targetID); err != nil {
		http.Error(w, "failed to unblock user", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "user unblocked"})
}

// GetBlockedUsers handles GET /me/blocked — returns all users blocked by the authenticated user.
func (h *Handler) GetBlockedUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	blocked, err := h.repo.GetBlockedUsers(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to get blocked users", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(blocked)
}

