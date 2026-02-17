package tests

import (
	"context"
	"testing"
	"time"

	"github.com/muskan953/college-Hop/internal/auth"
)

func TestAuthRepository_SaveAndVerifyOTP(t *testing.T) {
	if testDB == nil {
		t.Skip("Skipping integration test: DB not connected")
	}

	repo := auth.NewRepository(testDB)
	ctx := context.Background()
	email := "test_auth_repo@nitw.ac.in"
	otpHash := "hashed-otp-secret"
	expiresAt := time.Now().Add(10 * time.Minute)

	// Clean up before test
	clearTables(t, "otp_verifications", "users")

	// 1. Save OTP
	err := repo.SaveOTP(ctx, email, otpHash, expiresAt)
	if err != nil {
		t.Fatalf("Failed to save OTP: %v", err)
	}

	// 2. Verify OTP (Success)
	err = repo.VerifyOTP(ctx, email, otpHash)
	if err != nil {
		t.Errorf("Failed to verify valid OTP: %v", err)
	}

	// 3. Verify OTP again (Should fail because used=true)
	err = repo.VerifyOTP(ctx, email, otpHash)
	if err == nil {
		t.Error("VerifyOTP should fail for already used OTP")
	}
}

func TestAuthRepository_RateLimit(t *testing.T) {
	if testDB == nil {
		t.Skip("Skipping integration test: DB not connected")
	}

	repo := auth.NewRepository(testDB)
	ctx := context.Background()
	email := "rate_limit@nitw.ac.in"
	otpHash := "hash"
	expiresAt := time.Now().Add(10 * time.Minute)

	clearTables(t, "otp_verifications")

	// 1. Initial request should be allowed
	allowed, err := repo.CanRequestOTP(ctx, email)
	if err != nil {
		t.Fatalf("CanRequestOTP failed: %v", err)
	}
	if !allowed {
		t.Fatal("Expected CanRequestOTP to be true initially")
	}

	// 2. Save an OTP (simulating request sent)
	repo.SaveOTP(ctx, email, otpHash, expiresAt)

	// 3. Immediate next request should be blocked
	allowed, err = repo.CanRequestOTP(ctx, email)
	if err != nil {
		t.Fatalf("CanRequestOTP failed: %v", err)
	}
	if allowed {
		t.Error("Expected CanRequestOTP to be false immediately after request")
	}
}
