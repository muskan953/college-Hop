package auth

import (
	"crypto/sha256"
	"encoding/hex"
)

// HashOTP hashes the OTP using SHA-256
func HashOTP(otp string) string {
	hash := sha256.Sum256([]byte(otp))
	return hex.EncodeToString(hash[:])
}
