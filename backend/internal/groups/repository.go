package groups

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// ErrGroupFull is returned by JoinGroupChecked when the group has reached max capacity.
var ErrGroupFull = errors.New("group is full")

type Repository interface {
	CreateGroup(ctx context.Context, group *Group) error
	GetGroup(ctx context.Context, groupID string) (*Group, error)
	GetGroupThreadID(ctx context.Context, groupID string) (string, error)
	// JoinGroup is a plain insert used internally (e.g. auto-join on create).
	JoinGroup(ctx context.Context, groupID, userID string) error
	// JoinGroupChecked atomically checks capacity and joins in one transaction.
	// Returns ErrGroupFull if the group is already at max capacity.
	JoinGroupChecked(ctx context.Context, groupID, userID string) error
	GetMemberCount(ctx context.Context, groupID string) (int, error)
	// GetGroupsForEvent is kept for backward compatibility; prefer GetGroupsWithCountsForEvent.
	GetGroupsForEvent(ctx context.Context, eventID string) ([]Group, error)
	// GetGroupsWithCountsForEvent returns all groups for an event with live member counts
	// in a single query (replaces GetGroupsForEvent + per-group GetMemberCount).
	GetGroupsWithCountsForEvent(ctx context.Context, eventID string) ([]GroupWithDetails, error)
	// GetGroupMemberInterestsForEvent returns all member interest lists for every group in
	// an event in a single query, keyed by group ID. Replaces the per-group loop.
	GetGroupMemberInterestsForEvent(ctx context.Context, eventID string) (map[string][][]string, error)
	GetGroupMemberInterests(ctx context.Context, groupID string) ([][]string, error)
	// GetUsersForEvent returns users attending an event with their interests in one query.
	GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]UserWithInterests, error)
	GetUserInterests(ctx context.Context, userID string) ([]string, error)
	// Group management
	GetGroupMembers(ctx context.Context, groupID string) ([]GroupMemberProfile, error)
	UpdateGroup(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error
	DeleteGroup(ctx context.Context, groupID string) error
	RemoveMember(ctx context.Context, groupID, userID string) error
	IsGroupMember(ctx context.Context, groupID, userID string) (bool, error)
	GetUserGroups(ctx context.Context, userID string) ([]GroupWithDetails, error)
	// GetAllGroups returns all travel groups along with member count and whether
	// the given userID is currently a member of each group.
	GetAllGroups(ctx context.Context, userID string) ([]GroupWithDetails, error)
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
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	err = tx.QueryRowContext(ctx,
		`INSERT INTO travel_groups (event_id, name, description, created_by, max_members, departure_date, meeting_point)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 RETURNING id`,
		group.EventID, group.Name, group.Description, group.CreatedBy, group.MaxMembers,
		group.DepartureDate, group.MeetingPoint,
	).Scan(&group.ID)
	if err != nil {
		return err
	}

	// Wait, to safely insert into message_threads without failing if user is missing, it's fine
	_, err = tx.ExecContext(ctx,
		`INSERT INTO message_threads (type, group_id) VALUES ('group', $1)`,
		group.ID,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (r *PostgresRepository) GetGroup(ctx context.Context, groupID string) (*Group, error) {
	var g Group
	err := r.db.QueryRowContext(ctx,
		`SELECT id, event_id, name, COALESCE(description, ''), created_by, max_members, created_at,
		        departure_date, COALESCE(meeting_point, '')
		 FROM travel_groups WHERE id = $1`, groupID,
	).Scan(&g.ID, &g.EventID, &g.Name, &g.Description, &g.CreatedBy, &g.MaxMembers, &g.CreatedAt,
		&g.DepartureDate, &g.MeetingPoint)
	if err != nil {
		return nil, err
	}
	return &g, nil
}

func (r *PostgresRepository) GetGroupThreadID(ctx context.Context, groupID string) (string, error) {
	var threadID string
	err := r.db.QueryRowContext(ctx, `SELECT id FROM message_threads WHERE group_id = $1 AND type = 'group' LIMIT 1`, groupID).Scan(&threadID)
	if err == sql.ErrNoRows {
		// Backwards compatibility: Create the thread if it doesn't exist for older groups
		err = r.db.QueryRowContext(ctx,
			`INSERT INTO message_threads (type, group_id) VALUES ('group', $1) RETURNING id`,
			groupID,
		).Scan(&threadID)
		
		if err == nil {
			// Backfill all current group members into thread_participants
			_, _ = r.db.ExecContext(ctx,
				`INSERT INTO thread_participants (thread_id, user_id)
				 SELECT $1, user_id FROM group_members WHERE group_id = $2
				 ON CONFLICT DO NOTHING`,
				threadID, groupID,
			)
		}
		return threadID, err
	}
	return threadID, err
}

// JoinGroup is a plain insert â€” used for the auto-join when creating a group.
func (r *PostgresRepository) JoinGroup(ctx context.Context, groupID, userID string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(ctx,
		`INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)
		 ON CONFLICT DO NOTHING`,
		groupID, userID)
	if err != nil {
		return err
	}

	var threadID string
	err = tx.QueryRowContext(ctx, `SELECT id FROM message_threads WHERE group_id = $1 AND type = 'group' LIMIT 1`, groupID).Scan(&threadID)
	if err == nil {
		_, err = tx.ExecContext(ctx,
			`INSERT INTO thread_participants (thread_id, user_id) VALUES ($1, $2)
			 ON CONFLICT DO NOTHING`,
			threadID, userID)
		if err != nil {
			return err
		}
	} else if err != sql.ErrNoRows {
		return err
	}

	return tx.Commit()
}

// JoinGroupChecked performs an atomic capacity check + insert inside a transaction.
// It locks the travel_groups row with SELECT FOR UPDATE, counts current members,
// and only inserts if the group is not yet full.
func (r *PostgresRepository) JoinGroupChecked(ctx context.Context, groupID, userID string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Lock the group row to prevent concurrent joins from racing past the capacity check.
	var maxMembers int
	if err := tx.QueryRowContext(ctx,
		`SELECT max_members FROM travel_groups WHERE id = $1 FOR UPDATE`,
		groupID,
	).Scan(&maxMembers); err != nil {
		return err
	}

	var count int
	if err := tx.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM group_members WHERE group_id = $1`,
		groupID,
	).Scan(&count); err != nil {
		return err
	}

	if count >= maxMembers {
		return ErrGroupFull
	}

	_, err = tx.ExecContext(ctx,
		`INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)
		 ON CONFLICT DO NOTHING`,
		groupID, userID,
	)
	if err != nil {
		return err
	}

	var threadID string
	err = tx.QueryRowContext(ctx, `SELECT id FROM message_threads WHERE group_id = $1 AND type = 'group' LIMIT 1`, groupID).Scan(&threadID)
	if err == nil {
		_, err = tx.ExecContext(ctx,
			`INSERT INTO thread_participants (thread_id, user_id) VALUES ($1, $2)
			 ON CONFLICT DO NOTHING`,
			threadID, userID)
		if err != nil {
			return err
		}
	} else if err != sql.ErrNoRows {
		return err
	}

	return tx.Commit()
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
		`SELECT id, event_id, name, COALESCE(description, ''), created_by, max_members, created_at,
		        departure_date, COALESCE(meeting_point, '')
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
		if err := rows.Scan(&g.ID, &g.EventID, &g.Name, &g.Description, &g.CreatedBy, &g.MaxMembers, &g.CreatedAt,
			&g.DepartureDate, &g.MeetingPoint); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}
	return groups, nil
}

// GetGroupsWithCountsForEvent returns all groups for an event together with live
// member counts â€” a single query using a correlated subcount.
func (r *PostgresRepository) GetGroupsWithCountsForEvent(ctx context.Context, eventID string) ([]GroupWithDetails, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT tg.id, tg.event_id, tg.name, COALESCE(tg.description, ''),
		        tg.created_by, tg.max_members, tg.created_at,
		        tg.departure_date, COALESCE(tg.meeting_point, ''),
		        (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = tg.id) AS member_count
		 FROM travel_groups tg
		 WHERE tg.event_id = $1
		 ORDER BY tg.created_at DESC`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []GroupWithDetails
	for rows.Next() {
		var g GroupWithDetails
		if err := rows.Scan(
			&g.ID, &g.EventID, &g.Name, &g.Description,
			&g.CreatedBy, &g.MaxMembers, &g.CreatedAt,
			&g.DepartureDate, &g.MeetingPoint, &g.MemberCount,
		); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}
	return groups, nil
}

// GetGroupMemberInterestsForEvent returns member interests for every group in an
// event in a single query, keyed by group ID as a list-of-per-member-lists.
// This replaces the per-group GetGroupMemberInterests loop in SuggestedGroups.
func (r *PostgresRepository) GetGroupMemberInterestsForEvent(ctx context.Context, eventID string) (map[string][][]string, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT gm.group_id, gm.user_id, i.name
		 FROM group_members gm
		 JOIN travel_groups tg ON gm.group_id = tg.id
		 JOIN user_interests ui ON gm.user_id = ui.user_id
		 JOIN interests i ON ui.interest_id = i.id
		 WHERE tg.event_id = $1
		 ORDER BY gm.group_id, gm.user_id`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// groupID -> memberID -> interests (accumulate per row, then collapse)
	type memberKey struct{ groupID, userID string }
	memberInterests := make(map[memberKey][]string)
	var keys []memberKey // insertion-order dedup

	for rows.Next() {
		var groupID, userID, interest string
		if err := rows.Scan(&groupID, &userID, &interest); err != nil {
			return nil, err
		}
		k := memberKey{groupID, userID}
		if _, exists := memberInterests[k]; !exists {
			keys = append(keys, k)
		}
		memberInterests[k] = append(memberInterests[k], interest)
	}

	// Collapse to map[groupID][][]string
	result := make(map[string][][]string)
	seen := make(map[memberKey]bool)
	for _, k := range keys {
		if seen[k] {
			continue
		}
		seen[k] = true
		result[k.groupID] = append(result[k.groupID], memberInterests[k])
	}
	return result, nil
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

// GetUsersForEvent returns users attending an event with their interests using a
// single LEFT JOIN query â€” no more N+1 per-user interest loop.
func (r *PostgresRepository) GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]UserWithInterests, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT ue.user_id, p.full_name, p.college_name, COALESCE(p.profile_photo_url, ''),
		        COALESCE(i.name, '')
		 FROM user_events ue
		 JOIN profiles p ON ue.user_id = p.user_id
		 LEFT JOIN user_interests ui ON ue.user_id = ui.user_id
		 LEFT JOIN interests i ON ui.interest_id = i.id
		 WHERE ue.event_id = $1 AND ue.user_id != $2
		 ORDER BY ue.user_id`, eventID, excludeUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var order []string
	usersMap := make(map[string]*UserWithInterests)

	for rows.Next() {
		var userID, fullName, collegeName, photoURL, interest string
		if err := rows.Scan(&userID, &fullName, &collegeName, &photoURL, &interest); err != nil {
			return nil, err
		}
		if _, exists := usersMap[userID]; !exists {
			order = append(order, userID)
			usersMap[userID] = &UserWithInterests{
				UserID:          userID,
				FullName:        fullName,
				CollegeName:     collegeName,
				ProfilePhotoURL: photoURL,
			}
		}
		if interest != "" {
			usersMap[userID].Interests = append(usersMap[userID].Interests, interest)
		}
	}

	users := make([]UserWithInterests, 0, len(order))
	for _, id := range order {
		users = append(users, *usersMap[id])
	}
	return users, nil
}

// GetGroupMembers returns profile details for all members of a group
func (r *PostgresRepository) GetGroupMembers(ctx context.Context, groupID string) ([]GroupMemberProfile, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT gm.user_id, p.full_name, p.college_name, COALESCE(p.profile_photo_url, ''), gm.joined_at
		 FROM group_members gm
		 JOIN profiles p ON gm.user_id = p.user_id
		 WHERE gm.group_id = $1
		 ORDER BY gm.joined_at ASC`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []GroupMemberProfile
	for rows.Next() {
		var m GroupMemberProfile
		if err := rows.Scan(&m.UserID, &m.FullName, &m.CollegeName, &m.ProfilePhotoURL, &m.JoinedAt); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, nil
}

// UpdateGroup updates the name, description, departure_date, and meeting_point of a group
func (r *PostgresRepository) UpdateGroup(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE travel_groups SET name = $1, description = $2, departure_date = $3, meeting_point = $4 WHERE id = $5`,
		name, description, departureDate, meetingPoint, groupID)
	return err
}

// DeleteGroup removes a group and all its members (cascade via FK or manual)
func (r *PostgresRepository) DeleteGroup(ctx context.Context, groupID string) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM travel_groups WHERE id = $1`, groupID)
	return err
}

// RemoveMember removes a single user from a group
func (r *PostgresRepository) RemoveMember(ctx context.Context, groupID, userID string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(ctx,
		`DELETE FROM group_members WHERE group_id = $1 AND user_id = $2`,
		groupID, userID)
	if err != nil {
		return err
	}

	var threadID string
	err = tx.QueryRowContext(ctx, `SELECT id FROM message_threads WHERE group_id = $1 AND type = 'group' LIMIT 1`, groupID).Scan(&threadID)
	if err == nil {
		_, err = tx.ExecContext(ctx,
			`DELETE FROM thread_participants WHERE thread_id = $1 AND user_id = $2`,
			threadID, userID)
		if err != nil {
			return err
		}
	} else if err != sql.ErrNoRows {
		return err
	}

	return tx.Commit()
}

// IsGroupMember returns true if the user is currently a member of the group
func (r *PostgresRepository) IsGroupMember(ctx context.Context, groupID, userID string) (bool, error) {
	var count int
	err := r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND user_id = $2`,
		groupID, userID).Scan(&count)
	return count > 0, err
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

// GetUserGroups returns all groups the user is currently a member of, with live member counts.
func (r *PostgresRepository) GetUserGroups(ctx context.Context, userID string) ([]GroupWithDetails, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT tg.id, tg.event_id, tg.name, COALESCE(tg.description, ''), tg.created_by, tg.max_members, tg.created_at,
		        tg.departure_date, COALESCE(tg.meeting_point, ''),
		        (SELECT COUNT(*) FROM group_members gm2 WHERE gm2.group_id = tg.id) AS member_count
		 FROM group_members gm
		 JOIN travel_groups tg ON gm.group_id = tg.id
		 WHERE gm.user_id = $1
		 ORDER BY tg.created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []GroupWithDetails
	for rows.Next() {
		var g GroupWithDetails
		if err := rows.Scan(
			&g.ID, &g.EventID, &g.Name, &g.Description,
			&g.CreatedBy, &g.MaxMembers, &g.CreatedAt,
			&g.DepartureDate, &g.MeetingPoint, &g.MemberCount,
		); err != nil {
			return nil, err
		}
		g.IsJoined = true // the user is a member of every group returned by this query
		groups = append(groups, g)
	}
	return groups, nil
}

// GetAllGroups returns all travel groups with live member counts and a flag indicating
// whether the given user is already a member.
func (r *PostgresRepository) GetAllGroups(ctx context.Context, userID string) ([]GroupWithDetails, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT tg.id, tg.event_id, tg.name, COALESCE(tg.description, ''),
		        tg.created_by, tg.max_members, tg.created_at,
		        tg.departure_date, COALESCE(tg.meeting_point, ''),
		        (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = tg.id) AS member_count,
		        EXISTS (SELECT 1 FROM group_members gm2 WHERE gm2.group_id = tg.id AND gm2.user_id = $1) AS is_joined
		 FROM travel_groups tg
		 ORDER BY tg.created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []GroupWithDetails
	for rows.Next() {
		var g GroupWithDetails
		if err := rows.Scan(
			&g.ID, &g.EventID, &g.Name, &g.Description,
			&g.CreatedBy, &g.MaxMembers, &g.CreatedAt,
			&g.DepartureDate, &g.MeetingPoint, &g.MemberCount, &g.IsJoined,
		); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}
	return groups, nil
}
