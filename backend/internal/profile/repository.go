package profile

import (
	"context"
	"database/sql"
	"time"
)

type Repository interface {
	UpsertProfile(ctx context.Context, userID string, req UpdateProfileRequest) error
	GetProfile(ctx context.Context, userID string) (*ProfileResponse, error)
	UpsertPreferences(ctx context.Context, userID string, req UpdatePreferencesRequest) error
	GetPreferences(ctx context.Context, userID string) (*PreferencesResponse, error)
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
		id_expiration, bio, profile_photo_url, college_id_card_url, alternate_email, updated_at
	) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
	ON CONFLICT (user_id) DO UPDATE SET
		full_name = EXCLUDED.full_name,
		college_name = EXCLUDED.college_name,
		major = EXCLUDED.major,
		roll_number = EXCLUDED.roll_number,
		id_expiration = EXCLUDED.id_expiration,
		bio = EXCLUDED.bio,
		profile_photo_url = EXCLUDED.profile_photo_url,
		college_id_card_url = EXCLUDED.college_id_card_url,
		alternate_email = EXCLUDED.alternate_email,
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
		req.AlternateEmail,
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
	var idExpiration sql.NullTime
	var fullName, collegeName, major, rollNumber, bio, profilePhotoURL, idCardURL, alternateEmail sql.NullString

	err := r.db.QueryRowContext(ctx, `
		SELECT
			COALESCE(p.full_name, ''),
			COALESCE(p.college_name, ''),
			COALESCE(p.major, ''),
			COALESCE(p.roll_number, ''),
			p.id_expiration,
			COALESCE(p.bio, ''),
			COALESCE(p.profile_photo_url, ''),
			COALESCE(p.college_id_card_url, ''),
			COALESCE(p.alternate_email, ''),
		    COALESCE(u.status, '')
		FROM users u
		LEFT JOIN profiles p ON u.id = p.user_id
		WHERE u.id = $1
	`, userID).Scan(
		&fullName,
		&collegeName,
		&major,
		&rollNumber,
		&idExpiration,
		&bio,
		&profilePhotoURL,
		&idCardURL,
		&alternateEmail,
		&profile.Status,
	)

	if err != nil {
		return nil, err
	}

	// Map NullString values
	profile.FullName = fullName.String
	profile.CollegeName = collegeName.String
	profile.Major = major.String
	profile.RollNumber = rollNumber.String
	profile.Bio = bio.String
	profile.ProfilePhotoURL = profilePhotoURL.String
	profile.IDCardURL = idCardURL.String
	profile.AlternateEmail = alternateEmail.String

	// Compute IsAlumni: id_expiration is in the past
	if idExpiration.Valid {
		profile.IDExpiration = idExpiration.Time.Format("2006-01-02")
		profile.IsAlumni = idExpiration.Time.Before(time.Now())
	}

	// Fetch interests
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

	// Count events the user has expressed interest in
	err = r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM user_events WHERE user_id = $1`, userID,
	).Scan(&profile.EventsCount)
	if err != nil {
		profile.EventsCount = 0
	}

	// Count groups the user is a member of
	err = r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM group_members WHERE user_id = $1`, userID,
	).Scan(&profile.GroupsCount)
	if err != nil {
		profile.GroupsCount = 0
	}

	// Count confirmed connections
	err = r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM connections WHERE (user_id_1 = $1 OR user_id_2 = $1) AND status = 'connected'`, userID,
	).Scan(&profile.ConnectionsCount)
	if err != nil {
		profile.ConnectionsCount = 0
	}

	return &profile, nil
}

func (r *PostgresRepository) UpsertPreferences(ctx context.Context, userID string, req UpdatePreferencesRequest) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO user_preferences (
			user_id, profile_visibility, show_location, push_notifications,
			email_notifications, new_match_alerts, message_alerts, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (user_id) DO UPDATE SET
			profile_visibility  = EXCLUDED.profile_visibility,
			show_location       = EXCLUDED.show_location,
			push_notifications  = EXCLUDED.push_notifications,
			email_notifications = EXCLUDED.email_notifications,
			new_match_alerts    = EXCLUDED.new_match_alerts,
			message_alerts      = EXCLUDED.message_alerts,
			updated_at          = EXCLUDED.updated_at
	`,
		userID,
		req.ProfileVisibility,
		req.ShowLocation,
		req.PushNotifications,
		req.EmailNotifications,
		req.NewMatchAlerts,
		req.MessageAlerts,
		time.Now(),
	)
	return err
}

func (r *PostgresRepository) GetPreferences(ctx context.Context, userID string) (*PreferencesResponse, error) {
	var prefs PreferencesResponse
	err := r.db.QueryRowContext(ctx, `
		SELECT profile_visibility, show_location, push_notifications,
		       email_notifications, new_match_alerts, message_alerts
		FROM user_preferences
		WHERE user_id = $1
	`, userID).Scan(
		&prefs.ProfileVisibility,
		&prefs.ShowLocation,
		&prefs.PushNotifications,
		&prefs.EmailNotifications,
		&prefs.NewMatchAlerts,
		&prefs.MessageAlerts,
	)
	if err == sql.ErrNoRows {
		// Return defaults if preferences haven't been set yet
		return &PreferencesResponse{
			ProfileVisibility:  "public",
			ShowLocation:       true,
			PushNotifications:  true,
			EmailNotifications: true,
			NewMatchAlerts:     true,
			MessageAlerts:      true,
		}, nil
	}
	if err != nil {
		return nil, err
	}
	return &prefs, nil
}
