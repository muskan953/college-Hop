package auth

import (
	"context"
	"database/sql"
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

	var storedHash string
	var expiresAt time.Time
	var used bool

	err = tx.QueryRowContext(ctx,
		`SELECT otp_hash, expires_at, used
		 FROM otp_verifications
		 WHERE email = $1`,
		email,
	).Scan(&storedHash, &expiresAt, &used)

	if err != nil {
		return err
	}

	if used {
		return sql.ErrNoRows
	}

	if time.Now().After(expiresAt) {
		return sql.ErrNoRows
	}

	if storedHash != otpHash {
		return sql.ErrNoRows
	}

	// Mark as used
	_, err = tx.ExecContext(ctx,
		`UPDATE otp_verifications SET used = TRUE WHERE email = $1`,
		email,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
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
