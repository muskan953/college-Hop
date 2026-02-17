package groups

import (
	"context"
	"database/sql"
)

type Repository interface {
	CreateGroup(ctx context.Context, group *Group) error
	GetGroup(ctx context.Context, groupID string) (*Group, error)
	JoinGroup(ctx context.Context, groupID, userID string) error
	GetMemberCount(ctx context.Context, groupID string) (int, error)
	GetGroupsForEvent(ctx context.Context, eventID string) ([]Group, error)
	GetGroupMemberInterests(ctx context.Context, groupID string) ([][]string, error)
	GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]UserWithInterests, error)
	GetUserInterests(ctx context.Context, userID string) ([]string, error)
}

// UserWithInterests holds a user's profile data and interests for matching
type UserWithInterests struct {
	UserID          string
	FullName        string
	CollegeName     string
	ProfilePhotoURL string
	Interests       []string
}

type PostgresRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &PostgresRepository{db: db}
}

func (r *PostgresRepository) CreateGroup(ctx context.Context, group *Group) error {
	return r.db.QueryRowContext(ctx,
		`INSERT INTO travel_groups (event_id, name, description, created_by, max_members)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id`,
		group.EventID, group.Name, group.Description, group.CreatedBy, group.MaxMembers,
	).Scan(&group.ID)
}

func (r *PostgresRepository) GetGroup(ctx context.Context, groupID string) (*Group, error) {
	var g Group
	err := r.db.QueryRowContext(ctx,
		`SELECT id, event_id, name, COALESCE(description, ''), created_by, max_members, created_at
		 FROM travel_groups WHERE id = $1`, groupID,
	).Scan(&g.ID, &g.EventID, &g.Name, &g.Description, &g.CreatedBy, &g.MaxMembers, &g.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &g, nil
}

func (r *PostgresRepository) JoinGroup(ctx context.Context, groupID, userID string) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)
		 ON CONFLICT DO NOTHING`,
		groupID, userID)
	return err
}

func (r *PostgresRepository) GetMemberCount(ctx context.Context, groupID string) (int, error) {
	var count int
	err := r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM group_members WHERE group_id = $1`, groupID,
	).Scan(&count)
	return count, err
}

func (r *PostgresRepository) GetGroupsForEvent(ctx context.Context, eventID string) ([]Group, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT id, event_id, name, COALESCE(description, ''), created_by, max_members, created_at
		 FROM travel_groups
		 WHERE event_id = $1
		 ORDER BY created_at DESC`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []Group
	for rows.Next() {
		var g Group
		if err := rows.Scan(&g.ID, &g.EventID, &g.Name, &g.Description, &g.CreatedBy, &g.MaxMembers, &g.CreatedAt); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}
	return groups, nil
}

// GetGroupMemberInterests returns a list of interest lists, one per member
func (r *PostgresRepository) GetGroupMemberInterests(ctx context.Context, groupID string) ([][]string, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT gm.user_id, i.name
		 FROM group_members gm
		 JOIN user_interests ui ON gm.user_id = ui.user_id
		 JOIN interests i ON ui.interest_id = i.id
		 WHERE gm.group_id = $1
		 ORDER BY gm.user_id`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	memberInterests := make(map[string][]string)
	for rows.Next() {
		var userID, interest string
		if err := rows.Scan(&userID, &interest); err != nil {
			return nil, err
		}
		memberInterests[userID] = append(memberInterests[userID], interest)
	}

	var result [][]string
	for _, interests := range memberInterests {
		result = append(result, interests)
	}
	return result, nil
}

// GetUsersForEvent returns users attending an event with their interests (for peer matching)
func (r *PostgresRepository) GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]UserWithInterests, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT ue.user_id, p.full_name, p.college_name, COALESCE(p.profile_photo_url, '')
		 FROM user_events ue
		 JOIN profiles p ON ue.user_id = p.user_id
		 WHERE ue.event_id = $1 AND ue.user_id != $2`, eventID, excludeUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []UserWithInterests
	for rows.Next() {
		var u UserWithInterests
		if err := rows.Scan(&u.UserID, &u.FullName, &u.CollegeName, &u.ProfilePhotoURL); err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	// Fetch interests for each user
	for i := range users {
		interests, err := r.GetUserInterests(ctx, users[i].UserID)
		if err != nil {
			return nil, err
		}
		users[i].Interests = interests
	}

	return users, nil
}

func (r *PostgresRepository) GetUserInterests(ctx context.Context, userID string) ([]string, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT i.name
		 FROM user_interests ui
		 JOIN interests i ON ui.interest_id = i.id
		 WHERE ui.user_id = $1`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var interests []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, err
		}
		interests = append(interests, name)
	}
	return interests, nil
}
