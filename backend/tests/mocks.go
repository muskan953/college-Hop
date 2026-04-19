package tests

import (
	"context"
	"io"
	"time"

	"github.com/muskan953/college-Hop/internal/admin"
	"github.com/muskan953/college-Hop/internal/events"
	"github.com/muskan953/college-Hop/internal/groups"
	"github.com/muskan953/college-Hop/internal/profile"
)

// ensure MockAuthRepository implements auth.Repository
type MockAuthRepository struct {
	SaveOTPFunc            func(ctx context.Context, email string, otpHash string, expiresAt time.Time) error
	VerifyOTPFunc          func(ctx context.Context, email string, otpHash string) error
	CanRequestOTPFunc      func(ctx context.Context, email string) (bool, error)
	GetOrCreateUserFunc    func(ctx context.Context, email string) (string, error)
	SaveRefreshTokenFunc   func(ctx context.Context, userID string, tokenHash string, expiresAt time.Time) error
	GetRefreshTokenFunc    func(ctx context.Context, tokenHash string) (string, time.Time, error)
	DeleteRefreshTokenFunc func(ctx context.Context, tokenHash string) error
	UserExistsFunc         func(ctx context.Context, email string) (bool, error)
	GetUserStatusFunc      func(ctx context.Context, userID string) (string, error)
}

func (m *MockAuthRepository) SaveOTP(ctx context.Context, email string, otpHash string, expiresAt time.Time) error {
	if m.SaveOTPFunc != nil {
		return m.SaveOTPFunc(ctx, email, otpHash, expiresAt)
	}
	return nil
}

func (m *MockAuthRepository) VerifyOTP(ctx context.Context, email string, otpHash string) error {
	if m.VerifyOTPFunc != nil {
		return m.VerifyOTPFunc(ctx, email, otpHash)
	}
	return nil
}

func (m *MockAuthRepository) CanRequestOTP(ctx context.Context, email string) (bool, error) {
	if m.CanRequestOTPFunc != nil {
		return m.CanRequestOTPFunc(ctx, email)
	}
	return true, nil
}

func (m *MockAuthRepository) GetOrCreateUser(ctx context.Context, email string) (string, error) {
	if m.GetOrCreateUserFunc != nil {
		return m.GetOrCreateUserFunc(ctx, email)
	}
	return "mock-user-id", nil
}

func (m *MockAuthRepository) SaveRefreshToken(ctx context.Context, userID string, tokenHash string, expiresAt time.Time) error {
	if m.SaveRefreshTokenFunc != nil {
		return m.SaveRefreshTokenFunc(ctx, userID, tokenHash, expiresAt)
	}
	return nil
}

func (m *MockAuthRepository) GetRefreshToken(ctx context.Context, tokenHash string) (string, time.Time, error) {
	if m.GetRefreshTokenFunc != nil {
		return m.GetRefreshTokenFunc(ctx, tokenHash)
	}
	return "mock-user-id", time.Now().Add(30 * 24 * time.Hour), nil
}

func (m *MockAuthRepository) DeleteRefreshToken(ctx context.Context, tokenHash string) error {
	if m.DeleteRefreshTokenFunc != nil {
		return m.DeleteRefreshTokenFunc(ctx, tokenHash)
	}
	return nil
}

func (m *MockAuthRepository) UserExists(ctx context.Context, email string) (bool, error) {
	if m.UserExistsFunc != nil {
		return m.UserExistsFunc(ctx, email)
	}
	return false, nil
}

func (m *MockAuthRepository) GetUserStatus(ctx context.Context, userID string) (string, error) {
	if m.GetUserStatusFunc != nil {
		return m.GetUserStatusFunc(ctx, userID)
	}
	// Default: user is active — existing tests stay green
	return "verified", nil
}

// ensure MockProfileRepository implements profile.Repository
type MockProfileRepository struct {
	UpsertProfileFunc func(ctx context.Context, userID string, req profile.UpdateProfileRequest) error
	GetProfileFunc    func(ctx context.Context, userID string) (*profile.ProfileResponse, error)
}

func (m *MockProfileRepository) UpsertProfile(ctx context.Context, userID string, req profile.UpdateProfileRequest) error {
	if m.UpsertProfileFunc != nil {
		return m.UpsertProfileFunc(ctx, userID, req)
	}
	return nil
}

func (m *MockProfileRepository) GetProfile(ctx context.Context, userID string) (*profile.ProfileResponse, error) {
	if m.GetProfileFunc != nil {
		return m.GetProfileFunc(ctx, userID)
	}
	return &profile.ProfileResponse{}, nil
}
func (m *MockProfileRepository) UpsertPreferences(ctx context.Context, userID string, req profile.UpdatePreferencesRequest) error {
	return nil
}
func (m *MockProfileRepository) GetPreferences(ctx context.Context, userID string) (*profile.PreferencesResponse, error) {
	return &profile.PreferencesResponse{}, nil
}
func (m *MockProfileRepository) GetPublicProfile(ctx context.Context, userID string) (*profile.PublicProfileResponse, error) {
	return &profile.PublicProfileResponse{}, nil
}
func (m *MockProfileRepository) CreateConnection(ctx context.Context, userID1, userID2, status string, requesterID *string) error {
	return nil
}
func (m *MockProfileRepository) GetConnections(ctx context.Context, userID string) ([]profile.ConnectionResponse, error) {
	return []profile.ConnectionResponse{}, nil
}
func (m *MockProfileRepository) SaveAlternateEmail(ctx context.Context, userID, email string) error {
	return nil
}
func (m *MockProfileRepository) BlockUser(ctx context.Context, blockerID, blockedID string) error {
	return nil
}
func (m *MockProfileRepository) UnblockUser(ctx context.Context, blockerID, blockedID string) error {
	return nil
}
func (m *MockProfileRepository) GetBlockedUsers(ctx context.Context, userID string) ([]profile.BlockedUserResponse, error) {
	return []profile.BlockedUserResponse{}, nil
}

// ensure MockFileStorage implements storage.FileStorage
type MockFileStorage struct {
	UploadFunc func(filename string, file io.Reader) (string, error)
	DeleteFunc func(filename string) error
}

func (m *MockFileStorage) Upload(filename string, file io.Reader) (string, error) {
	if m.UploadFunc != nil {
		return m.UploadFunc(filename, file)
	}
	return "http://mock-storage.com/" + filename, nil
}

func (m *MockFileStorage) Delete(filename string) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(filename)
	}
	return nil
}

// MockAdminRepository implements admin.Repository
type MockAdminRepository struct {
	ListUsersByStatusFunc func(ctx context.Context, status string) ([]admin.UserRow, error)
	UpdateUserStatusFunc  func(ctx context.Context, userID string, status string) error
}

func (m *MockAdminRepository) ListUsersByStatus(ctx context.Context, status string) ([]admin.UserRow, error) {
	if m.ListUsersByStatusFunc != nil {
		return m.ListUsersByStatusFunc(ctx, status)
	}
	return []admin.UserRow{}, nil
}

func (m *MockAdminRepository) UpdateUserStatus(ctx context.Context, userID string, status string) error {
	if m.UpdateUserStatusFunc != nil {
		return m.UpdateUserStatusFunc(ctx, userID, status)
	}
	return nil
}

// MockEventsRepository implements events.Repository
type MockEventsRepository struct{}

func (m *MockEventsRepository) CreateEvent(ctx context.Context, event *events.Event) error {
	return nil
}
func (m *MockEventsRepository) ListApprovedEvents(ctx context.Context) ([]events.Event, error) {
	return []events.Event{}, nil
}
func (m *MockEventsRepository) ListPendingEvents(ctx context.Context) ([]events.Event, error) {
	return []events.Event{}, nil
}
func (m *MockEventsRepository) UpdateEventStatus(ctx context.Context, eventID string, status string) error {
	return nil
}
func (m *MockEventsRepository) GetEvent(ctx context.Context, eventID string) (*events.Event, error) {
	return &events.Event{}, nil
}
func (m *MockEventsRepository) SetUserEvent(ctx context.Context, userID, eventID, status string) error {
	return nil
}
func (m *MockEventsRepository) GetUserEvent(ctx context.Context, userID string) (*events.UserEvent, error) {
	return &events.UserEvent{}, nil
}
func (m *MockEventsRepository) GetUserEvents(ctx context.Context, userID string) ([]events.UserEventDetails, error) {
	return []events.UserEventDetails{}, nil
}

// MockGroupsRepository implements groups.Repository
type MockGroupsRepository struct{}

func (m *MockGroupsRepository) CreateGroup(ctx context.Context, group *groups.Group) error {
	return nil
}
func (m *MockGroupsRepository) GetGroup(ctx context.Context, groupID string) (*groups.Group, error) {
	return &groups.Group{}, nil
}
func (m *MockGroupsRepository) GetGroupThreadID(ctx context.Context, groupID string) (string, error) {
	return "mock-thread-id", nil
}
func (m *MockGroupsRepository) JoinGroup(ctx context.Context, groupID, userID string) error {
	return nil
}
func (m *MockGroupsRepository) JoinGroupChecked(ctx context.Context, groupID, userID string) error {
	return nil
}
func (m *MockGroupsRepository) GetMemberCount(ctx context.Context, groupID string) (int, error) {
	return 0, nil
}
func (m *MockGroupsRepository) GetGroupsForEvent(ctx context.Context, eventID string) ([]groups.Group, error) {
	return []groups.Group{}, nil
}
func (m *MockGroupsRepository) GetGroupsWithCountsForEvent(ctx context.Context, eventID string) ([]groups.GroupWithDetails, error) {
	return []groups.GroupWithDetails{}, nil
}
func (m *MockGroupsRepository) GetGroupMemberInterestsForEvent(ctx context.Context, eventID string) (map[string][][]string, error) {
	return map[string][][]string{}, nil
}
func (m *MockGroupsRepository) GetGroupMemberInterests(ctx context.Context, groupID string) ([][]string, error) {
	return [][]string{}, nil
}
func (m *MockGroupsRepository) GetUsersForEvent(ctx context.Context, eventID, excludeUserID string) ([]groups.UserWithInterests, error) {
	return []groups.UserWithInterests{}, nil
}
func (m *MockGroupsRepository) GetUserInterests(ctx context.Context, userID string) ([]string, error) {
	return []string{}, nil
}
func (m *MockGroupsRepository) GetGroupMembers(ctx context.Context, groupID string) ([]groups.GroupMemberProfile, error) {
	return []groups.GroupMemberProfile{}, nil
}
func (m *MockGroupsRepository) UpdateGroup(ctx context.Context, groupID, name, description, meetingPoint string, departureDate *time.Time) error {
	return nil
}
func (m *MockGroupsRepository) DeleteGroup(ctx context.Context, groupID string) error {
	return nil
}
func (m *MockGroupsRepository) RemoveMember(ctx context.Context, groupID, userID string) error {
	return nil
}
func (m *MockGroupsRepository) IsGroupMember(ctx context.Context, groupID, userID string) (bool, error) {
	return false, nil
}
func (m *MockGroupsRepository) GetUserGroups(ctx context.Context, userID string) ([]groups.GroupWithDetails, error) {
	return []groups.GroupWithDetails{}, nil
}
func (m *MockGroupsRepository) GetAllGroups(ctx context.Context, userID string) ([]groups.GroupWithDetails, error) {
	return []groups.GroupWithDetails{}, nil
}


