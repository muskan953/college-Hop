package auth

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type SignupRequest struct {
	Email string `json:"email"`
}

type SignupResponse struct {
	Message string `json:"message"`
}

type VerifyRequest struct {
	Email string `json:"email"`
	OTP   string `json:"otp"`
}

type VerifyResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type RefreshResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

type Handler struct {
	repo Repository
}

func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Signup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req SignupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if err := ValidateEmail(req.Email); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	allowed, err := h.repo.CanRequestOTP(r.Context(), req.Email)
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}

	if !allowed {
		http.Error(w, "please wait before requesting another OTP", http.StatusTooManyRequests)
		return
	}

	otp, err := GenerateOTP()
	if err != nil {
		http.Error(w, "failed to generate OTP", http.StatusInternalServerError)
		return
	}

	otpHash := HashOTP(otp)
	expiresAt := OTPExpiry()

	// Save OTP to database
	err = h.repo.SaveOTP(r.Context(), req.Email, otpHash, expiresAt)
	if err != nil {
		http.Error(w, "failed to save otp", http.StatusInternalServerError)
		return
	}

	// TEMP: log OTP (remove in production)
	log.Printf("OTP for %s: %s", req.Email, otp)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(SignupResponse{
		Message: "OTP sent",
	})
}

func (h *Handler) Verify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req VerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	otpHash := HashOTP(req.OTP)

	err := h.repo.VerifyOTP(r.Context(), req.Email, otpHash)
	if err != nil {
		http.Error(w, "invalid or expired otp", http.StatusUnauthorized)
		return
	}

	userID, err := h.repo.GetOrCreateUser(r.Context(), req.Email)
	if err != nil {
		http.Error(w, "failed to create user", http.StatusInternalServerError)
		return
	}

	accessToken, err := GenerateToken(userID, req.Email)
	if err != nil {
		http.Error(w, "failed to generate access token", http.StatusInternalServerError)
		return
	}

	refreshToken, err := GenerateRefreshToken(userID, req.Email)
	if err != nil {
		http.Error(w, "failed to generate refresh token", http.StatusInternalServerError)
		return
	}

	// Save hashed refresh token to DB
	tokenHash := HashOTP(refreshToken)
	expiresAt := time.Now().Add(30 * 24 * time.Hour)
	if err := h.repo.SaveRefreshToken(r.Context(), userID, tokenHash, expiresAt); err != nil {
		http.Error(w, "failed to save refresh token", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(VerifyResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

func (h *Handler) Refresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// 1. Validate the refresh token (parse as JWT)
	claims, err := ParseToken(req.RefreshToken)
	if err != nil {
		http.Error(w, "invalid refresh token", http.StatusUnauthorized)
		return
	}

	// 2. Check the DB for the hashed token (to handle revocation and rotation)
	tokenHash := HashOTP(req.RefreshToken)
	userID, expiresAt, err := h.repo.GetRefreshToken(r.Context(), tokenHash)
	if err != nil {
		http.Error(w, "refresh token revoked or not found", http.StatusUnauthorized)
		return
	}

	if time.Now().After(expiresAt) {
		h.repo.DeleteRefreshToken(r.Context(), tokenHash)
		http.Error(w, "refresh token expired", http.StatusUnauthorized)
		return
	}

	// 3. Rotation: Invalidate the old refresh token
	if err := h.repo.DeleteRefreshToken(r.Context(), tokenHash); err != nil {
		http.Error(w, "failed to rotate token", http.StatusInternalServerError)
		return
	}

	// 4. Generate new pair
	accessToken, err := GenerateToken(userID, claims.Email)
	if err != nil {
		http.Error(w, "failed to generate access token", http.StatusInternalServerError)
		return
	}

	newRefreshToken, err := GenerateRefreshToken(userID, claims.Email)
	if err != nil {
		http.Error(w, "failed to generate refresh token", http.StatusInternalServerError)
		return
	}

	// 5. Save the NEW refresh token
	newTokenHash := HashOTP(newRefreshToken)
	newExpiresAt := time.Now().Add(30 * 24 * time.Hour)
	if err := h.repo.SaveRefreshToken(r.Context(), userID, newTokenHash, newExpiresAt); err != nil {
		http.Error(w, "failed to save new refresh token", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(RefreshResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
	})
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RefreshRequest // We reuse the RefreshRequest struct since it just needs the token
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	tokenHash := HashOTP(req.RefreshToken)
	if err := h.repo.DeleteRefreshToken(r.Context(), tokenHash); err != nil {
		http.Error(w, "failed to logout", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "logged out successfully"})
}
