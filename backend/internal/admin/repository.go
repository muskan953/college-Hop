package admin

import (
	"context"
	"database/sql"
)

// UserRow represents a user with their profile data for admin review.
type UserRow struct {
	UserID    string  `json:"user_id"`
	Email     string  `json:"email"`
	Status    string  `json:"status"`
	FullName  *string `json:"full_name"`
	College   *string `json:"college_name"`
	IDCardURL *string `json:"college_id_card_url"`
}

type Repository interface {
	ListUsersByStatus(ctx context.Context, status string) ([]UserRow, error)
	UpdateUserStatus(ctx context.Context, userID string, status string) error
}

type PostgresRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &PostgresRepository{db: db}
}

func (r *PostgresRepository) ListUsersByStatus(ctx context.Context, status string) ([]UserRow, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT u.id, u.email, u.status,
		       p.full_name, p.college_name, p.college_id_card_url
		FROM users u
		LEFT JOIN profiles p ON p.user_id = u.id
		WHERE u.status = $1
		ORDER BY u.created_at DESC
	`, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []UserRow
	for rows.Next() {
		var u UserRow
		if err := rows.Scan(&u.UserID, &u.Email, &u.Status, &u.FullName, &u.College, &u.IDCardURL); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, rows.Err()
}

func (r *PostgresRepository) UpdateUserStatus(ctx context.Context, userID string, status string) error {
	result, err := r.db.ExecContext(ctx, `UPDATE users SET status = $1 WHERE id = $2`, status, userID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}
	return nil
}
