package auth

import (
	"encoding/json"
	"log"
	"net/http"
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
	Token string `json:"token"`
}

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
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

	token, err := GenerateToken(userID, req.Email)
	if err != nil {
		http.Error(w, "failed to generate token", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(VerifyResponse{
		Token: token,
	})
}
