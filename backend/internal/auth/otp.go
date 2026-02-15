package auth

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"time"
)

func OTPExpiry() time.Time {
	return time.Now().Add(5 * time.Minute)
}

// GenerateOTP returns a secure 6-digit numeric OTP
func GenerateOTP() (string, error) {
	max := big.NewInt(900000) // range size
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}

	otp := 100000 + n.Int64()
	return fmt.Sprintf("%06d", otp), nil
}
