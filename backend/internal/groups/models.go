package groups

import "time"

// Group represents a travel group for an event
type Group struct {
	ID          string    `json:"id"`
	EventID     string    `json:"event_id"`
	Name        string    `json:"name"`
	Description string    `json:"description,omitempty"`
	CreatedBy   string    `json:"created_by"`
	MaxMembers  int       `json:"max_members"`
	CreatedAt   time.Time `json:"created_at"`
}

// GroupWithDetails includes member count and match info for API responses
type GroupWithDetails struct {
	Group
	MemberCount int      `json:"member_count"`
	MatchScore  float64  `json:"match_score"`
	Interests   []string `json:"interests"` // combined unique interests of all members
}

// CreateGroupRequest is the payload for POST /groups
type CreateGroupRequest struct {
	EventID     string `json:"event_id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	MaxMembers  int    `json:"max_members"`
}

// GroupMember represents a member in a travel group
type GroupMember struct {
	GroupID  string    `json:"group_id"`
	UserID   string    `json:"user_id"`
	JoinedAt time.Time `json:"joined_at"`
}

// GroupMemberProfile contains displayable info about a group member
type GroupMemberProfile struct {
	UserID          string    `json:"user_id"`
	FullName        string    `json:"full_name"`
	CollegeName     string    `json:"college_name"`
	ProfilePhotoURL string    `json:"profile_photo_url,omitempty"`
	JoinedAt        time.Time `json:"joined_at"`
}

// GroupDetailResponse is returned by GET /groups/{id} — full group info with members
type GroupDetailResponse struct {
	Group
	MemberCount int                  `json:"member_count"`
	Members     []GroupMemberProfile `json:"members"`
}

// UpdateGroupRequest is the payload for PUT /groups/{id}
type UpdateGroupRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

// KickRequest is the payload for POST /groups/{id}/kick
type KickRequest struct {
	UserID string `json:"user_id"`
}

// MatchedUser represents a peer match result
type MatchedUser struct {
	UserID          string   `json:"user_id"`
	FullName        string   `json:"full_name"`
	CollegeName     string   `json:"college_name"`
	ProfilePhotoURL string   `json:"profile_photo_url,omitempty"`
	CommonInterests []string `json:"common_interests"`
	MatchScore      float64  `json:"match_score"`
}
