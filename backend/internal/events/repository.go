package events

import (
	"context"
	"database/sql"
	"time"
)

type Repository interface {
	CreateEvent(ctx context.Context, event *Event) error
	ListApprovedEvents(ctx context.Context) ([]Event, error)
	ListPendingEvents(ctx context.Context) ([]Event, error)
	UpdateEventStatus(ctx context.Context, eventID string, status string) error
	GetEvent(ctx context.Context, eventID string) (*Event, error)
	SetUserEvent(ctx context.Context, userID, eventID, status string) error
	GetUserEvent(ctx context.Context, userID string) (*UserEvent, error)
}

type PostgresRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &PostgresRepository{db: db}
}

func (r *PostgresRepository) CreateEvent(ctx context.Context, event *Event) error {
	return r.db.QueryRowContext(ctx,
		`INSERT INTO events (name, date, location, organizer, url, submitted_by, status, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		 RETURNING id`,
		event.Name, event.Date, event.Location, event.Organizer, event.URL,
		event.SubmittedBy, event.Status, time.Now(),
	).Scan(&event.ID)
}

func (r *PostgresRepository) ListApprovedEvents(ctx context.Context) ([]Event, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT id, name, date, location, organizer, COALESCE(url, ''), status, created_at
		 FROM events
		 WHERE status = 'approved'
		 ORDER BY date ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []Event
	for rows.Next() {
		var e Event
		if err := rows.Scan(&e.ID, &e.Name, &e.Date, &e.Location, &e.Organizer, &e.URL, &e.Status, &e.CreatedAt); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	return events, nil
}

func (r *PostgresRepository) ListPendingEvents(ctx context.Context) ([]Event, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT id, name, date, location, organizer, COALESCE(url, ''), COALESCE(submitted_by::text, ''), status, created_at
		 FROM events
		 WHERE status = 'pending'
		 ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []Event
	for rows.Next() {
		var e Event
		if err := rows.Scan(&e.ID, &e.Name, &e.Date, &e.Location, &e.Organizer, &e.URL, &e.SubmittedBy, &e.Status, &e.CreatedAt); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	return events, nil
}

func (r *PostgresRepository) UpdateEventStatus(ctx context.Context, eventID string, status string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE events SET status = $1 WHERE id = $2`,
		status, eventID)
	return err
}

func (r *PostgresRepository) GetEvent(ctx context.Context, eventID string) (*Event, error) {
	var e Event
	err := r.db.QueryRowContext(ctx,
		`SELECT id, name, date, location, organizer, COALESCE(url, ''), status, created_at
		 FROM events WHERE id = $1`, eventID,
	).Scan(&e.ID, &e.Name, &e.Date, &e.Location, &e.Organizer, &e.URL, &e.Status, &e.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &e, nil
}

func (r *PostgresRepository) SetUserEvent(ctx context.Context, userID, eventID, status string) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO user_events (user_id, event_id, status)
		 VALUES ($1, $2, $3)
		 ON CONFLICT (user_id, event_id) DO UPDATE SET status = EXCLUDED.status`,
		userID, eventID, status)
	return err
}

func (r *PostgresRepository) GetUserEvent(ctx context.Context, userID string) (*UserEvent, error) {
	var ue UserEvent
	err := r.db.QueryRowContext(ctx,
		`SELECT user_id, event_id, status
		 FROM user_events
		 WHERE user_id = $1
		 ORDER BY created_at DESC
		 LIMIT 1`, userID,
	).Scan(&ue.UserID, &ue.EventID, &ue.Status)
	if err != nil {
		return nil, err
	}
	return &ue, nil
}
