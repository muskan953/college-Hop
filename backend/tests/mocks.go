package tests

import (
	"context"
	"io"
	"time"

	"github.com/muskan953/college-Hop/internal/admin"
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
