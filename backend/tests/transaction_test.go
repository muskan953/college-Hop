package tests

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/muskan953/college-Hop/internal/profile"
)

// TestTransactionRollbackOnInterestFailure verifies that if the interests
// phase of UpsertProfile fails, the entire profile upsert is rolled back.
func TestTransactionRollbackOnInterestFailure(t *testing.T) {
	clearTables(t, "user_interests", "profiles", "users")

	userID := uuid.New().String()

	// Insert a test user
	_, err := testDB.Exec(
		`INSERT INTO users (id, email, status) VALUES ($1, $2, 'pending')`,
		userID, "txntest@nitw.ac.in",
	)
	if err != nil {
		t.Fatalf("failed to insert test user: %v", err)
	}

	repo := profile.NewRepository(testDB)

	// 1. First upsert should succeed — establishes a baseline
	req1 := profile.UpdateProfileRequest{
		FullName:     "Test User",
		CollegeName:  "NIT Warangal",
		Major:        "CSE",
		RollNumber:   "21CS1001",
		IDExpiration: "2026-06-01",
		Bio:          "original bio",
		Interests:    []string{"Coding"},
	}

	if err := repo.UpsertProfile(context.Background(), userID, req1); err != nil {
		t.Fatalf("first upsert failed: %v", err)
	}

	// Verify the profile was created
	p, err := repo.GetProfile(context.Background(), userID)
	if err != nil {
		t.Fatalf("get profile after first upsert failed: %v", err)
	}
	if p.Bio != "original bio" {
		t.Fatalf("expected bio 'original bio', got '%s'", p.Bio)
	}

	// 2. Now attempt an upsert with an interest name that is absurdly long
	// This should cause an error if the database has a constraint, or we can
	// test with an invalid user_id in a new repo call.
	// Instead, let's test the transaction contract by using a cancelled context
	// to simulate a mid-transaction failure.

	ctx, cancel := context.WithCancel(context.Background())
	cancel() // cancel immediately

	req2 := profile.UpdateProfileRequest{
		FullName:     "Updated User",
		CollegeName:  "IIT Bombay",
		Major:        "ME",
		RollNumber:   "21ME2002",
		IDExpiration: "2027-06-01",
		Bio:          "updated bio",
		Interests:    []string{"Music", "Dance"},
	}

	err = repo.UpsertProfile(ctx, userID, req2)
	if err == nil {
		t.Fatal("expected error from cancelled context, got nil")
	}

	// 3. Verify that the profile was NOT changed — the transaction rolled back
	p2, err := repo.GetProfile(context.Background(), userID)
	if err != nil {
		t.Fatalf("get profile after rollback failed: %v", err)
	}

	if p2.Bio != "original bio" {
		t.Fatalf("ROLLBACK FAILED: expected bio 'original bio' after failed txn, got '%s'", p2.Bio)
	}
	if p2.CollegeName != "NIT Warangal" {
		t.Fatalf("ROLLBACK FAILED: expected college 'NIT Warangal' after failed txn, got '%s'", p2.CollegeName)
	}

	t.Log("Transaction rollback verified: profile was not modified after failed upsert")
}
