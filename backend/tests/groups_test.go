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
		GetMemberCountFunc: func(ctx context.Context, groupID string) (int, error) {
			return 4, nil // already full
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

// MockGroupsRepositoryFull allows overriding individual methods
type MockGroupsRepositoryFull struct {
	CreateGroupFunc             func(ctx context.Context, group *groups.Group) error
	GetGroupFunc                func(ctx context.Context, groupID string) (*groups.Group, error)
	JoinGroupFunc               func(ctx context.Context, groupID, userID string) error
	GetMemberCountFunc          func(ctx context.Context, groupID string) (int, error)
	GetGroupsForEventFunc       func(ctx context.Context, eventID string) ([]groups.Group, error)
	GetGroupMemberInterestsFunc func(ctx context.Context, groupID string) ([][]string, error)
	GetUsersForEventFunc        func(ctx context.Context, eventID, excludeUserID string) ([]groups.UserWithInterests, error)
	GetUserInterestsFunc        func(ctx context.Context, userID string) ([]string, error)
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
