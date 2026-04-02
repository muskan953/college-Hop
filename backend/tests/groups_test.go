package tests

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/groups"
	"github.com/muskan953/college-Hop/internal/server"
)

// --- Groups Handler Tests ---

func TestCreateGroup_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		CreateGroupFunc: func(ctx context.Context, group *groups.Group) error {
			group.ID = "grp-1"
			return nil
		},
		JoinGroupFunc: func(ctx context.Context, groupID, userID string) error {
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]interface{}{
		"event_id":    "evt-1",
		"name":        "Team Alpha",
		"description": "Looking for travel buddies",
		"max_members": 4,
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("POST /groups: got status %d, want %d. Body: %s", rr.Code, http.StatusCreated, rr.Body.String())
	}
}

func TestCreateGroup_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]interface{}{
		"event_id": "evt-1",
		"name":     "Team Alpha",
	}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("POST /groups without auth: got %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

func TestCreateGroup_ValidationFails(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	// Missing event_id and name
	payload := map[string]interface{}{"max_members": 4}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups with missing fields: got %d, want %d", rr.Code, http.StatusBadRequest)
	}
}

func TestJoinGroup_GroupFull(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: "grp-1", MaxMembers: 4}, nil
		},
		JoinGroupCheckedFunc: func(ctx context.Context, groupID, userID string) error {
			return groups.ErrGroupFull // atomic check says full
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/groups/grp-1/join", nil)
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups/{id}/join (full): got %d, want %d. Body: %s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}

func TestSuggestedGroups_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/groups/suggested?event_id=evt-1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /groups/suggested without auth: got %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

func TestSuggestedGroups_RequiresEventID(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetUserInterestsFunc: func(ctx context.Context, userID string) ([]string, error) {
			return []string{"AI", "ML"}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/groups/suggested", nil) // missing event_id
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("GET /groups/suggested without event_id: got %d, want %d", rr.Code, http.StatusBadRequest)
	}
}

func TestFindMatches_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/users/matches?event_id=evt-1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /users/matches without auth: got %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

func TestFindMatches_ReturnsScoredResults(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetUserInterestsFunc: func(ctx context.Context, userID string) ([]string, error) {
			return []string{"AI", "ML", "Robotics"}, nil
		},
		GetUsersForEventFunc: func(ctx context.Context, eventID, excludeUserID string) ([]groups.UserWithInterests, error) {
			return []groups.UserWithInterests{
				{UserID: "u1", FullName: "Alice", CollegeName: "NIT W", Interests: []string{"AI", "ML", "Cloud"}},
				{UserID: "u2", FullName: "Bob", CollegeName: "IIIT H", Interests: []string{"Music", "Art"}},
				{UserID: "u3", FullName: "Charlie", CollegeName: "NIT W", Interests: []string{"AI", "ML", "Robotics", "DevOps"}},
			}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/users/matches?event_id=evt-1", nil)
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /users/matches: got status %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}

	var matches []groups.MatchedUser
	if err := json.NewDecoder(rr.Body).Decode(&matches); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	// Bob (no overlap) should be filtered out
	for _, m := range matches {
		if m.UserID == "u2" {
			t.Error("Bob (no matching interests) should have been filtered out")
		}
	}

	// Results should be sorted by score descending
	if len(matches) >= 2 {
		if matches[0].MatchScore < matches[1].MatchScore {
			t.Errorf("matches should be sorted by score desc: %.4f < %.4f", matches[0].MatchScore, matches[1].MatchScore)
		}
	}

	// Charlie (3/4 overlap) should be first
	if len(matches) > 0 && matches[0].UserID != "u3" {
		t.Errorf("Charlie (best match) should be first, got %s", matches[0].FullName)
	}
}

// --- GetGroup Tests ---

func TestGetGroup_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, Name: "Team Alpha", MaxMembers: 4, CreatedBy: "creator-id"}, nil
		},
		GetGroupMembersFunc: func(ctx context.Context, groupID string) ([]groups.GroupMemberProfile, error) {
			return []groups.GroupMemberProfile{
				{UserID: "creator-id", FullName: "Muskan Sharma", CollegeName: "NIT Warangal"},
			}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/groups/grp-1", nil)
	token, _ := auth.GenerateToken("test-user-id", "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /groups/{id}: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}

	var resp groups.GroupDetailResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if resp.Name != "Team Alpha" {
		t.Errorf("expected group name 'Team Alpha', got '%s'", resp.Name)
	}
	if resp.MemberCount != 1 {
		t.Errorf("expected member_count 1, got %d", resp.MemberCount)
	}
}

func TestGetGroup_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/groups/grp-1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /groups/{id} without auth: got %d, want 401", rr.Code)
	}
}

// --- UpdateGroup Tests ---

func TestUpdateGroup_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, Name: "Old Name", CreatedBy: creatorID, MaxMembers: 4}, nil
		},
		UpdateGroupFunc: func(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error {
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"name": "New Name", "description": "Updated description"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("PUT", "/groups/grp-1", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("PUT /groups/{id}: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestUpdateGroup_ForbiddenForNonCreator(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: "actual-creator-id", MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"name": "Hacked Name"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("PUT", "/groups/grp-1", bytes.NewBuffer(body))

	// Different user JWT — not the creator
	token, _ := auth.GenerateToken("some-other-user", "other@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("PUT /groups/{id} by non-creator: got %d, want 403", rr.Code)
	}
}

func TestUpdateGroup_MissingName(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"description": "Only description, no name"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("PUT", "/groups/grp-1", bytes.NewBuffer(body))

	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("PUT /groups/{id} with missing name: got %d, want 400", rr.Code)
	}
}

// --- DeleteGroup Tests ---

func TestDeleteGroup_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
		DeleteGroupFunc: func(ctx context.Context, groupID string) error {
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("DELETE", "/groups/grp-1", nil)
	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("DELETE /groups/{id}: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestDeleteGroup_ForbiddenForNonCreator(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: "actual-creator-id", MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("DELETE", "/groups/grp-1", nil)
	token, _ := auth.GenerateToken("some-other-user", "other@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("DELETE /groups/{id} by non-creator: got %d, want 403", rr.Code)
	}
}

// --- LeaveGroup Tests ---

func TestLeaveGroup_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	memberID := "member-user-id"

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
		IsGroupMemberFunc: func(ctx context.Context, groupID, userID string) (bool, error) {
			return true, nil
		},
		RemoveMemberFunc: func(ctx context.Context, groupID, userID string) error {
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/groups/grp-1/leave", nil)
	token, _ := auth.GenerateToken(memberID, "member@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("POST /groups/{id}/leave: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestLeaveGroup_CreatorCannotLeave(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/groups/grp-1/leave", nil)
	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups/{id}/leave by creator: got %d, want 400", rr.Code)
	}
}

func TestLeaveGroup_NotAMember(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: "creator-id", MaxMembers: 4}, nil
		},
		IsGroupMemberFunc: func(ctx context.Context, groupID, userID string) (bool, error) {
			return false, nil // not a member
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("POST", "/groups/grp-1/leave", nil)
	token, _ := auth.GenerateToken("random-user", "rando@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups/{id}/leave by non-member: got %d, want 400", rr.Code)
	}
}

// --- KickMember Tests ---

func TestKickMember_Success(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	targetID := "target-member-id"

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
		IsGroupMemberFunc: func(ctx context.Context, groupID, userID string) (bool, error) {
			return true, nil
		},
		RemoveMemberFunc: func(ctx context.Context, groupID, userID string) error {
			return nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"user_id": targetID}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups/grp-1/kick", bytes.NewBuffer(body))
	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("POST /groups/{id}/kick: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestKickMember_ForbiddenForNonCreator(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: "actual-creator", MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"user_id": "someone"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups/grp-1/kick", bytes.NewBuffer(body))
	token, _ := auth.GenerateToken("not-the-creator", "other@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("POST /groups/{id}/kick by non-creator: got %d, want 403", rr.Code)
	}
}

func TestKickMember_CannotKickSelf(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	// Try to kick yourself
	payload := map[string]string{"user_id": creatorID}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups/grp-1/kick", bytes.NewBuffer(body))
	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups/{id}/kick self: got %d, want 400", rr.Code)
	}
}

func TestKickMember_TargetNotInGroup(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	creatorID := "creator-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetGroupFunc: func(ctx context.Context, groupID string) (*groups.Group, error) {
			return &groups.Group{ID: groupID, CreatedBy: creatorID, MaxMembers: 4}, nil
		},
		IsGroupMemberFunc: func(ctx context.Context, groupID, userID string) (bool, error) {
			return false, nil // target is not in the group
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	payload := map[string]string{"user_id": "ghost-user"}
	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/groups/grp-1/kick", bytes.NewBuffer(body))
	token, _ := auth.GenerateToken(creatorID, "creator@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /groups/{id}/kick non-member: got %d, want 400", rr.Code)
	}
}

// MockGroupsRepositoryFull allows overriding individual methods

type MockGroupsRepositoryFull struct {
	CreateGroupFunc                     func(ctx context.Context, group *groups.Group) error
	GetGroupFunc                        func(ctx context.Context, groupID string) (*groups.Group, error)
	JoinGroupFunc                       func(ctx context.Context, groupID, userID string) error
	JoinGroupCheckedFunc                func(ctx context.Context, groupID, userID string) error
	GetMemberCountFunc                  func(ctx context.Context, groupID string) (int, error)
	GetGroupsForEventFunc               func(ctx context.Context, eventID string) ([]groups.Group, error)
	GetGroupsWithCountsForEventFunc     func(ctx context.Context, eventID string) ([]groups.GroupWithDetails, error)
	GetGroupMemberInterestsForEventFunc func(ctx context.Context, eventID string) (map[string][][]string, error)
	GetGroupMemberInterestsFunc         func(ctx context.Context, groupID string) ([][]string, error)
	GetUsersForEventFunc                func(ctx context.Context, eventID, excludeUserID string) ([]groups.UserWithInterests, error)
	GetUserInterestsFunc                func(ctx context.Context, userID string) ([]string, error)
	GetGroupMembersFunc                 func(ctx context.Context, groupID string) ([]groups.GroupMemberProfile, error)
	UpdateGroupFunc                     func(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error
	DeleteGroupFunc                     func(ctx context.Context, groupID string) error
	RemoveMemberFunc                    func(ctx context.Context, groupID, userID string) error
	IsGroupMemberFunc                   func(ctx context.Context, groupID, userID string) (bool, error)
	GetUserGroupsFunc                   func(ctx context.Context, userID string) ([]groups.GroupWithDetails, error)
}

func (m *MockGroupsRepositoryFull) CreateGroup(ctx context.Context, group *groups.Group) error {
	if m.CreateGroupFunc != nil {
		return m.CreateGroupFunc(ctx, group)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) GetGroup(ctx context.Context, groupID string) (*groups.Group, error) {
	if m.GetGroupFunc != nil {
		return m.GetGroupFunc(ctx, groupID)
	}
	return &groups.Group{MaxMembers: 4}, nil
}
func (m *MockGroupsRepositoryFull) JoinGroup(ctx context.Context, groupID, userID string) error {
	if m.JoinGroupFunc != nil {
		return m.JoinGroupFunc(ctx, groupID, userID)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) JoinGroupChecked(ctx context.Context, groupID, userID string) error {
	if m.JoinGroupCheckedFunc != nil {
		return m.JoinGroupCheckedFunc(ctx, groupID, userID)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) GetMemberCount(ctx context.Context, groupID string) (int, error) {
	if m.GetMemberCountFunc != nil {
		return m.GetMemberCountFunc(ctx, groupID)
	}
	return 1, nil
}
func (m *MockGroupsRepositoryFull) GetGroupsForEvent(ctx context.Context, eventID string) ([]groups.Group, error) {
	if m.GetGroupsForEventFunc != nil {
		return m.GetGroupsForEventFunc(ctx, eventID)
	}
	return []groups.Group{}, nil
}
func (m *MockGroupsRepositoryFull) GetGroupsWithCountsForEvent(ctx context.Context, eventID string) ([]groups.GroupWithDetails, error) {
	if m.GetGroupsWithCountsForEventFunc != nil {
		return m.GetGroupsWithCountsForEventFunc(ctx, eventID)
	}
	return []groups.GroupWithDetails{}, nil
}
func (m *MockGroupsRepositoryFull) GetGroupMemberInterestsForEvent(ctx context.Context, eventID string) (map[string][][]string, error) {
	if m.GetGroupMemberInterestsForEventFunc != nil {
		return m.GetGroupMemberInterestsForEventFunc(ctx, eventID)
	}
	return map[string][][]string{}, nil
}
func (m *MockGroupsRepositoryFull) GetGroupMemberInterests(ctx context.Context, groupID string) ([][]string, error) {
	if m.GetGroupMemberInterestsFunc != nil {
		return m.GetGroupMemberInterestsFunc(ctx, groupID)
	}
	return [][]string{}, nil
}
func (m *MockGroupsRepositoryFull) GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]groups.UserWithInterests, error) {
	if m.GetUsersForEventFunc != nil {
		return m.GetUsersForEventFunc(ctx, eventID, excludeUserID)
	}
	return []groups.UserWithInterests{}, nil
}
func (m *MockGroupsRepositoryFull) GetUserInterests(ctx context.Context, userID string) ([]string, error) {
	if m.GetUserInterestsFunc != nil {
		return m.GetUserInterestsFunc(ctx, userID)
	}
	return []string{}, nil
}
func (m *MockGroupsRepositoryFull) GetGroupMembers(ctx context.Context, groupID string) ([]groups.GroupMemberProfile, error) {
	if m.GetGroupMembersFunc != nil {
		return m.GetGroupMembersFunc(ctx, groupID)
	}
	return []groups.GroupMemberProfile{}, nil
}
func (m *MockGroupsRepositoryFull) UpdateGroup(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error {
	if m.UpdateGroupFunc != nil {
		return m.UpdateGroupFunc(ctx, groupID, name, description, meetingPoint, departureDate)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) DeleteGroup(ctx context.Context, groupID string) error {
	if m.DeleteGroupFunc != nil {
		return m.DeleteGroupFunc(ctx, groupID)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) RemoveMember(ctx context.Context, groupID, userID string) error {
	if m.RemoveMemberFunc != nil {
		return m.RemoveMemberFunc(ctx, groupID, userID)
	}
	return nil
}
func (m *MockGroupsRepositoryFull) IsGroupMember(ctx context.Context, groupID, userID string) (bool, error) {
	if m.IsGroupMemberFunc != nil {
		return m.IsGroupMemberFunc(ctx, groupID, userID)
	}
	return true, nil
}
func (m *MockGroupsRepositoryFull) GetUserGroups(ctx context.Context, userID string) ([]groups.GroupWithDetails, error) {
	if m.GetUserGroupsFunc != nil {
		return m.GetUserGroupsFunc(ctx, userID)
	}
	return []groups.GroupWithDetails{}, nil
}

// --- GetMyGroups Tests ---

func TestGetMyGroups_ReturnsGroups(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	userID := "test-user-id"
	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetUserGroupsFunc: func(ctx context.Context, uid string) ([]groups.GroupWithDetails, error) {
			return []groups.GroupWithDetails{
				{Group: groups.Group{ID: "grp-1", Name: "Team Alpha", EventID: "evt-1", CreatedBy: userID, MaxMembers: 4}, MemberCount: 2},
				{Group: groups.Group{ID: "grp-2", Name: "Team Beta", EventID: "evt-2", CreatedBy: "someone-else", MaxMembers: 6}, MemberCount: 1},
			}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/me/groups", nil)
	token, _ := auth.GenerateToken(userID, "student@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /me/groups: got %d, want %d. Body: %s", rr.Code, http.StatusOK, rr.Body.String())
	}

	var result []groups.GroupWithDetails
	if err := json.NewDecoder(rr.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode: %v", err)
	}
	if len(result) != 2 {
		t.Errorf("expected 2 groups, got %d", len(result))
	}
	if result[0].Name != "Team Alpha" {
		t.Errorf("expected first group to be 'Team Alpha', got '%s'", result[0].Name)
	}
}

func TestGetMyGroups_ReturnsEmptyWhenNone(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	mockGroupsRepo := &MockGroupsRepositoryFull{
		GetUserGroupsFunc: func(ctx context.Context, userID string) ([]groups.GroupWithDetails, error) {
			return []groups.GroupWithDetails{}, nil
		},
	}

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, mockGroupsRepo,
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/me/groups", nil)
	token, _ := auth.GenerateToken("user-no-groups", "newbie@nitw.ac.in")
	req.Header.Set("Authorization", "Bearer "+token)

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /me/groups empty: got %d, want %d", rr.Code, http.StatusOK)
	}

	var result []groups.GroupWithDetails
	if err := json.NewDecoder(rr.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode: %v", err)
	}
	if len(result) != 0 {
		t.Errorf("expected empty list, got %d groups", len(result))
	}
}

func TestGetMyGroups_RequiresAuth(t *testing.T) {
	t.Setenv("JWT_SECRET", "testsecret")

	router := server.NewRouter(
		&MockAuthRepository{}, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		&MockFileStorage{}, "./uploads",
	)

	req, _ := http.NewRequest("GET", "/me/groups", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /me/groups without auth: got %d, want 401", rr.Code)
	}
}
