package messages

import (
	"context"
	"database/sql"
	"time"
)

// Repository defines all data access operations for messaging.
type Repository interface {
	// Threads
	GetOrCreateDirectThread(ctx context.Context, userID1, userID2 string) (Thread, error)
	CreateGroupThread(ctx context.Context, groupID string, memberIDs []string) (Thread, error)
	ListUserThreads(ctx context.Context, userID string) ([]ThreadSummary, error)

	// Messages
	GetMessages(ctx context.Context, threadID, userID string, before time.Time, limit int) ([]Message, error)
	CreateMessage(ctx context.Context, threadID, senderID, content string) (Message, error)
	DeleteMessage(ctx context.Context, messageID, userID string) (string, error)

	// Thread management
	ClearThread(ctx context.Context, threadID, userID string) error
	MarkThreadAsRead(ctx context.Context, threadID, userID string) error

	// Membership
	IsParticipant(ctx context.Context, threadID, userID string) (bool, error)
	GetParticipantIDs(ctx context.Context, threadID string) ([]string, error)

	// Device tokens (push notifications)
	UpsertDeviceToken(ctx context.Context, userID, token, platform string) error
	GetDeviceTokens(ctx context.Context, userID string) ([]string, error)
	RemoveDeviceToken(ctx context.Context, userID, token string) error

	// Block check (delegates to connections table)
	IsBlocked(ctx context.Context, userID1, userID2 string) (bool, error)
}

// PostgresRepository implements Repository using database/sql.
type PostgresRepository struct {
	db *sql.DB
}

// NewRepository returns a new PostgresRepository.
func NewRepository(db *sql.DB) Repository {
	return &PostgresRepository{db: db}
}

// GetOrCreateDirectThread finds or creates a 1:1 thread between two users.
func (r *PostgresRepository) GetOrCreateDirectThread(ctx context.Context, userID1, userID2 string) (Thread, error) {
	// Check if a direct thread already exists between these two users
	var t Thread
	err := r.db.QueryRowContext(ctx, `
		SELECT mt.id, mt.type, mt.group_id, mt.created_at
		FROM message_threads mt
		JOIN thread_participants tp1 ON tp1.thread_id = mt.id AND tp1.user_id = $1
		JOIN thread_participants tp2 ON tp2.thread_id = mt.id AND tp2.user_id = $2
		WHERE mt.type = 'direct'
		LIMIT 1
	`, userID1, userID2).Scan(&t.ID, &t.Type, &t.GroupID, &t.CreatedAt)

	if err == nil {
		return t, nil // existing thread found
	}
	if err != sql.ErrNoRows {
		return Thread{}, err
	}

	// Create new thread + add both participants in a transaction
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return Thread{}, err
	}
	defer tx.Rollback()

	err = tx.QueryRowContext(ctx, `
		INSERT INTO message_threads (type) VALUES ('direct')
		RETURNING id, type, group_id, created_at
	`).Scan(&t.ID, &t.Type, &t.GroupID, &t.CreatedAt)
	if err != nil {
		return Thread{}, err
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO thread_participants (thread_id, user_id) VALUES ($1, $2), ($1, $3)
	`, t.ID, userID1, userID2)
	if err != nil {
		return Thread{}, err
	}

	return t, tx.Commit()
}

// CreateGroupThread creates a group chat thread linked to a travel_group.
func (r *PostgresRepository) CreateGroupThread(ctx context.Context, groupID string, memberIDs []string) (Thread, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return Thread{}, err
	}
	defer tx.Rollback()

	var t Thread
	err = tx.QueryRowContext(ctx, `
		INSERT INTO message_threads (type, group_id) VALUES ('group', $1)
		RETURNING id, type, group_id, created_at
	`, groupID).Scan(&t.ID, &t.Type, &t.GroupID, &t.CreatedAt)
	if err != nil {
		return Thread{}, err
	}

	for _, uid := range memberIDs {
		_, err = tx.ExecContext(ctx, `
			INSERT INTO thread_participants (thread_id, user_id)
			VALUES ($1, $2) ON CONFLICT DO NOTHING
		`, t.ID, uid)
		if err != nil {
			return Thread{}, err
		}
	}

	return t, tx.Commit()
}

// ListUserThreads returns all threads for a user with last message info.
func (r *PostgresRepository) ListUserThreads(ctx context.Context, userID string) ([]ThreadSummary, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT
			mt.id,
			mt.type,
			COALESCE(
				CASE WHEN mt.type = 'group' THEN tg.name
				     ELSE COALESCE(p.full_name, u.email)
				END,
				'Unknown'
			) AS other_user_name,
			COALESCE(lm.content, '') AS last_message,
			COALESCE(lm.created_at, mt.created_at) AS last_message_at,
			p2.profile_photo_url,
			COALESCE(tp_other.user_id::text, '') AS other_user_id,
			(
				SELECT COUNT(*)
				FROM messages m2
				WHERE m2.thread_id = mt.id
				  AND m2.sender_id != $1
				  AND m2.created_at > COALESCE(tp.last_read_at, '1970-01-01'::timestamptz)
				  AND m2.created_at > COALESCE(tp.cleared_at, '1970-01-01'::timestamptz)
			) AS unread_count
		FROM thread_participants tp
		JOIN message_threads mt ON mt.id = tp.thread_id
		-- For direct chats: get the OTHER participant's name
		LEFT JOIN thread_participants tp_other
			ON tp_other.thread_id = mt.id AND tp_other.user_id != $1 AND mt.type = 'direct'
		LEFT JOIN profiles p ON p.user_id = tp_other.user_id
		LEFT JOIN users u ON u.id = tp_other.user_id
		LEFT JOIN profiles p2 ON p2.user_id = tp_other.user_id
		-- For group chats: get the group name
		LEFT JOIN travel_groups tg ON tg.id = mt.group_id
		-- Last message (subquery for latest)
		LEFT JOIN LATERAL (
			SELECT content, created_at FROM messages
			WHERE thread_id = mt.id
			  AND created_at > COALESCE(tp.cleared_at, '1970-01-01'::timestamptz)
			ORDER BY created_at DESC LIMIT 1
		) lm ON true
		WHERE tp.user_id = $1
		  -- Only exclude if the other user IS identified and has blocked
		  AND NOT EXISTS (
			SELECT 1 FROM connections
			WHERE tp_other.user_id IS NOT NULL
			  AND ((user_id_1 = $1 AND user_id_2 = tp_other.user_id)
			    OR (user_id_1 = tp_other.user_id AND user_id_2 = $1))
			  AND status = 'blocked'
		  )
		ORDER BY COALESCE(lm.created_at, mt.created_at) DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var threads []ThreadSummary
	for rows.Next() {
		var ts ThreadSummary
		var avatarURL sql.NullString
		var otherUserID sql.NullString
		if err := rows.Scan(&ts.ID, &ts.Type, &ts.Name, &ts.LastMessage,
			&ts.LastMessageTime, &avatarURL, &otherUserID, &ts.UnreadCount); err != nil {
			return nil, err
		}
		if avatarURL.Valid {
			ts.AvatarURL = &avatarURL.String
		}
		if otherUserID.Valid && otherUserID.String != "" {
			ts.OtherUserID = &otherUserID.String
		}
		// Mirror Name to OtherUserName so both JSON fields are populated
		ts.OtherUserName = ts.Name
		threads = append(threads, ts)
	}
	return threads, rows.Err()
}

// GetMessages returns paginated messages for a thread, respecting cleared_at.
func (r *PostgresRepository) GetMessages(ctx context.Context, threadID, userID string, before time.Time, limit int) ([]Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT m.id, m.thread_id, COALESCE(m.sender_id::text, ''), COALESCE(p.full_name, 'Deleted User'), m.content, m.created_at
		FROM messages m
		LEFT JOIN profiles p ON p.user_id = m.sender_id
		JOIN thread_participants tp ON tp.thread_id = m.thread_id AND tp.user_id = $3
		WHERE m.thread_id = $1
		  AND m.created_at < $2
		  AND m.created_at > COALESCE(tp.cleared_at, '1970-01-01'::timestamptz)
		ORDER BY m.created_at DESC
		LIMIT $4
	`, threadID, before, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var msgs []Message
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.ThreadID, &m.SenderID, &m.SenderName, &m.Content, &m.CreatedAt); err != nil {
			return nil, err
		}
		msgs = append(msgs, m)
	}
	return msgs, rows.Err()
}

// CreateMessage inserts a new message and returns it with the sender name.
func (r *PostgresRepository) CreateMessage(ctx context.Context, threadID, senderID, content string) (Message, error) {
	var m Message
	err := r.db.QueryRowContext(ctx, `
		WITH inserted AS (
			INSERT INTO messages (thread_id, sender_id, content)
			VALUES ($1, $2, $3)
			RETURNING id, thread_id, sender_id, content, created_at
		)
		SELECT i.id, i.thread_id, i.sender_id::text, COALESCE(p.full_name, 'Unknown'), i.content, i.created_at
		FROM inserted i
		LEFT JOIN profiles p ON p.user_id = i.sender_id
	`, threadID, senderID, content).Scan(&m.ID, &m.ThreadID, &m.SenderID, &m.SenderName, &m.Content, &m.CreatedAt)
	return m, err
}

// DeleteMessage removes a message if it belongs to the requesting user and returns its thread ID.
func (r *PostgresRepository) DeleteMessage(ctx context.Context, messageID, userID string) (string, error) {
	var threadID string
	err := r.db.QueryRowContext(ctx, `
		DELETE FROM messages WHERE id = $1 AND sender_id = $2
		RETURNING thread_id
	`, messageID, userID).Scan(&threadID)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return "", sql.ErrNoRows
		}
		return "", err
	}
	
	return threadID, nil
}

// ClearThread sets cleared_at for a user, hiding older messages from their view.
func (r *PostgresRepository) ClearThread(ctx context.Context, threadID, userID string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE thread_participants SET cleared_at = NOW()
		WHERE thread_id = $1 AND user_id = $2
	`, threadID, userID)
	return err
}

// IsParticipant checks whether a user belongs to a thread.
func (r *PostgresRepository) IsParticipant(ctx context.Context, threadID, userID string) (bool, error) {
	var exists bool
	err := r.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM thread_participants WHERE thread_id = $1 AND user_id = $2
		)
	`, threadID, userID).Scan(&exists)
	return exists, err
}

// GetParticipantIDs returns all user IDs in a thread.
func (r *PostgresRepository) GetParticipantIDs(ctx context.Context, threadID string) ([]string, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT user_id FROM thread_participants WHERE thread_id = $1
	`, threadID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

// UpsertDeviceToken inserts or updates a device token for push notifications.
func (r *PostgresRepository) UpsertDeviceToken(ctx context.Context, userID, token, platform string) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO device_tokens (user_id, token, platform, updated_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (user_id, token)
		DO UPDATE SET platform = $3, updated_at = NOW()
	`, userID, token, platform)
	return err
}

// GetDeviceTokens returns all FCM tokens for a user.
func (r *PostgresRepository) GetDeviceTokens(ctx context.Context, userID string) ([]string, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT token FROM device_tokens WHERE user_id = $1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var t string
		if err := rows.Scan(&t); err != nil {
			return nil, err
		}
		tokens = append(tokens, t)
	}
	return tokens, rows.Err()
}

// RemoveDeviceToken deletes a specific device token (e.g., on logout).
func (r *PostgresRepository) RemoveDeviceToken(ctx context.Context, userID, token string) error {
	_, err := r.db.ExecContext(ctx, `
		DELETE FROM device_tokens WHERE user_id = $1 AND token = $2
	`, userID, token)
	return err
}

// IsBlocked checks if either user has blocked the other via the connections table.
func (r *PostgresRepository) IsBlocked(ctx context.Context, userID1, userID2 string) (bool, error) {
	var blocked bool
	err := r.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM connections
			WHERE ((user_id_1 = $1 AND user_id_2 = $2) OR (user_id_1 = $2 AND user_id_2 = $1))
			  AND status = 'blocked'
		)
	`, userID1, userID2).Scan(&blocked)
	return blocked, err
}

// MarkThreadAsRead updates the last_read_at timestamp for a user in a thread.
func (r *PostgresRepository) MarkThreadAsRead(ctx context.Context, threadID, userID string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE thread_participants
		SET last_read_at = NOW()
		WHERE thread_id = $1 AND user_id = $2
	`, threadID, userID)
	return err
}
