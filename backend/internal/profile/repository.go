package profile

import (
	"context"
	"database/sql"
	"time"
)

type Repository interface {
	UpsertProfile(ctx context.Context, userID string, req UpdateProfileRequest) error
	GetProfile(ctx context.Context, userID string) (*ProfileResponse, error)
}

type PostgresRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &PostgresRepository{db: db}
}

func (r *PostgresRepository) UpsertProfile(ctx context.Context, userID string, req UpdateProfileRequest) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// upsert profile
	_, err = tx.ExecContext(ctx, `
	INSERT INTO profiles (
		user_id, full_name, college_name, major, roll_number,
		id_expiration, bio, profile_photo_url, college_id_card_url, updated_at
	) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
	ON CONFLICT (user_id) DO UPDATE SET
		full_name = EXCLUDED.full_name,
		college_name = EXCLUDED.college_name,
		major = EXCLUDED.major,
		roll_number = EXCLUDED.roll_number,
		id_expiration = EXCLUDED.id_expiration,
		bio = EXCLUDED.bio,
		profile_photo_url = EXCLUDED.profile_photo_url,
		college_id_card_url = EXCLUDED.college_id_card_url,
		updated_at = EXCLUDED.updated_at
	`,
		userID,
		req.FullName,
		req.CollegeName,
		req.Major,
		req.RollNumber,
		req.IDExpiration,
		req.Bio,
		req.ProfilePhotoURL,
		req.IDCardURL,
		time.Now(),
	)

	if err != nil {
		return err
	}

	// remove old interests
	_, err = tx.ExecContext(ctx, `DELETE FROM user_interests WHERE user_id = $1`, userID)
	if err != nil {
		return err
	}

	// insert new interests
	for _, interest := range req.Interests {

		var interestID int

		err = tx.QueryRowContext(ctx,
			`INSERT INTO interests (name)
			 VALUES ($1)
			 ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			 RETURNING id`,
			interest,
		).Scan(&interestID)

		if err != nil {
			return err
		}

		_, err = tx.ExecContext(ctx,
			`INSERT INTO user_interests (user_id, interest_id)
			 VALUES ($1, $2)`,
			userID, interestID,
		)

		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (r *PostgresRepository) GetProfile(ctx context.Context, userID string) (*ProfileResponse, error) {

	var profile ProfileResponse

	err := r.db.QueryRowContext(ctx, `
		SELECT full_name, college_name, major, roll_number,
		       id_expiration, bio, profile_photo_url, college_id_card_url
		FROM profiles
		WHERE user_id = $1
	`, userID).Scan(
		&profile.FullName,
		&profile.CollegeName,
		&profile.Major,
		&profile.RollNumber,
		&profile.IDExpiration,
		&profile.Bio,
		&profile.ProfilePhotoURL,
		&profile.IDCardURL,
	)

	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT i.name
		FROM user_interests ui
		JOIN interests i ON ui.interest_id = i.id
		WHERE ui.user_id = $1
	`, userID)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var interest string
		if err := rows.Scan(&interest); err != nil {
			return nil, err
		}
		profile.Interests = append(profile.Interests, interest)
	}

	return &profile, nil
}
