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
		`INSERT INTO events
		    (name, category, venue, organizer, start_date, end_date, time_description,
		     event_link, brochure_url, ticket_link, submitted_by, status, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		 RETURNING id`,
		event.Name, event.Category, event.Venue, event.Organizer,
		event.StartDate, event.EndDate, event.TimeDescription,
		event.EventLink, event.BrochureURL, event.TicketLink,
		event.SubmittedBy, event.Status, time.Now(),
	).Scan(&event.ID)
}

func scanEvent(row interface {
	Scan(dest ...any) error
}, e *Event) error {
	var (
		category        sql.NullString
		endDate         sql.NullTime
		timeDescription sql.NullString
		eventLink       sql.NullString
		brochureURL     sql.NullString
		ticketLink      sql.NullString
	)
	err := row.Scan(
		&e.ID, &e.Name, &category, &e.Venue, &e.Organizer,
		&e.StartDate, &endDate, &timeDescription,
		&eventLink, &brochureURL, &ticketLink,
		&e.Status, &e.CreatedAt,
	)
	if err != nil {
		return err
	}
	if category.Valid {
		e.Category = category.String
	}
	if endDate.Valid {
		t := endDate.Time
		e.EndDate = &t
	}
	if timeDescription.Valid {
		e.TimeDescription = timeDescription.String
	}
	if eventLink.Valid {
		e.EventLink = eventLink.String
	}
	if brochureURL.Valid {
		e.BrochureURL = brochureURL.String
	}
	if ticketLink.Valid {
		e.TicketLink = ticketLink.String
	}
	return nil
}

const listEventColumns = `
	id, name, category, venue, organizer,
	start_date, end_date, time_description,
	event_link, brochure_url, ticket_link,
	status, created_at`

func (r *PostgresRepository) ListApprovedEvents(ctx context.Context) ([]Event, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT`+listEventColumns+`
		 FROM events
		 WHERE status = 'approved'
		 ORDER BY start_date ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []Event
	for rows.Next() {
		var e Event
		if err := scanEvent(rows, &e); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	return events, nil
}

func (r *PostgresRepository) ListPendingEvents(ctx context.Context) ([]Event, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT`+listEventColumns+`
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
		if err := scanEvent(rows, &e); err != nil {
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
	err := scanEvent(r.db.QueryRowContext(ctx,
		`SELECT`+listEventColumns+`
		 FROM events WHERE id = $1`, eventID), &e)
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
