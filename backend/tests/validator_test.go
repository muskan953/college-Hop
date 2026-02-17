package tests

import (
	"testing"

	"github.com/muskan953/college-Hop/internal/auth"
)

func TestValidateEmail(t *testing.T) {
	tests := []struct {
		name    string
		email   string
		wantErr error
	}{
		{
			name:    "valid student email",
			email:   "student@nitw.ac.in",
			wantErr: nil,
		},
		{
			name:    "invalid format",
			email:   "not-an-email",
			wantErr: auth.ErrInvalidEmail,
		},
		{
			name:    "blocked gmail",
			email:   "user@gmail.com",
			wantErr: auth.ErrNonStudentEmail,
		},
		{
			name:    "blocked yahoo",
			email:   "user@yahoo.com",
			wantErr: auth.ErrNonStudentEmail,
		},
		{
			name:    "other valid domain",
			email:   "prof@university.edu",
			wantErr: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := auth.ValidateEmail(tt.email)
			if err != tt.wantErr {
				t.Errorf("ValidateEmail() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
