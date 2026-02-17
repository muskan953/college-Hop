package tests

import (
	"context"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/profile"
)

func TestProfileRepository_UpsertAndGet(t *testing.T) {
	if testDB == nil {
		t.Skip("Skipping integration test: DB not connected")
	}

	repo := profile.NewRepository(testDB)
	authRepo := auth.NewRepository(testDB)
	ctx := context.Background()

	// Clean up
	clearTables(t, "user_interests", "profiles", "users", "interests")

	// 1. Create a user first (foreign key constraint)
	email := "profile_test@nitw.ac.in"
	userID, err := authRepo.GetOrCreateUser(ctx, email)
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}

	// 2. Upsert Profile
	req := profile.UpdateProfileRequest{
		FullName:        "Test Student",
		CollegeName:     "NIT Warangal",
		Major:           "CSE",
		RollNumber:      "123456",
		IDExpiration:    "2025-05-01",
		Bio:             "Hello world",
		ProfilePhotoURL: "http://example.com/photo.jpg",
		IDCardURL:       "http://example.com/id.pdf",
		Interests:       []string{"Coding", "Music"},
	}

	err = repo.UpsertProfile(ctx, userID, req)
	if err != nil {
		t.Fatalf("Failed to upsert profile: %v", err)
	}

	// 3. Get Profile
	p, err := repo.GetProfile(ctx, userID)
	if err != nil {
		t.Fatalf("Failed to get profile: %v", err)
	}

	if p.FullName != req.FullName {
		t.Errorf("Expected FullName %s, got %s", req.FullName, p.FullName)
	}
	if len(p.Interests) != 2 {
		t.Errorf("Expected 2 interests, got %d", len(p.Interests))
	}
}
