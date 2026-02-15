package auth

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) SaveOTP(ctx context.Context, email string, otpHash string, expiresAt time.Time) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Delete existing OTPs for this email
	_, err = tx.ExecContext(ctx,
		`DELETE FROM otp_verifications WHERE email = $1`,
		email,
	)
	if err != nil {
		return err
	}

	// Insert new OTP
	_, err = tx.ExecContext(ctx,
		`INSERT INTO otp_verifications (id, email, otp_hash, expires_at)
		 VALUES ($1, $2, $3, $4)`,
		uuid.New(),
		email,
		otpHash,
		expiresAt,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *Repository) VerifyOTP(ctx context.Context, email string, otpHash string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	var id string
	var storedHash string
	var attempts int

	// 1. Get the record
	err = tx.QueryRowContext(ctx, `
       SELECT id, otp_hash, attempts
       FROM otp_verifications
       WHERE email = $1 AND used = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1
       FOR UPDATE
    `, email).Scan(&id, &storedHash, &attempts)

	if err == sql.ErrNoRows {
		return errors.New("no valid otp found")
	}
	if err != nil {
		return err
	}

	// 2. Check if already blocked
	if attempts >= 5 {
		return errors.New("too many attempts, request a new code")
	}

	// 3. THE BRANCHING LOGIC
	if storedHash != otpHash {
		// Increment the attempt in the DB
		_, err = tx.ExecContext(ctx, `UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1`, id)
		if err != nil {
			return err
		}

		// COMMIT THE INCREMENT
		if commitErr := tx.Commit(); commitErr != nil {
			return commitErr
		}

		// STILL RETURN AN ERROR TO THE APP
		return errors.New("invalid otp")
	}

	// 4. SUCCESS PATH
	_, err = tx.ExecContext(ctx, `UPDATE otp_verifications SET used = TRUE WHERE id = $1`, id)
	if err != nil {
		return err
	}

	return tx.Commit() // Returns nil on success
}

func (r *Repository) CanRequestOTP(ctx context.Context, email string) (bool, error) {
	var exists bool

	err := r.db.QueryRowContext(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM otp_verifications
			WHERE email = $1
			AND created_at > NOW() - INTERVAL '30 seconds'
		)
	`, email).Scan(&exists)

	if err != nil {
		return false, err
	}

	return !exists, nil
}

func (r *Repository) GetOrCreateUser(ctx context.Context, email string) (string, error) {
	var id string

	err := r.db.QueryRowContext(ctx,
		`INSERT INTO users (id, email)
		 VALUES ($1, $2)
		 ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
		 RETURNING id`,
		uuid.New(),
		email,
	).Scan(&id)

	return id, err
}
