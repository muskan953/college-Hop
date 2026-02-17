package tests

import (
	"testing"

	"github.com/muskan953/college-Hop/internal/profile"
)

func TestIsValidUploadURL(t *testing.T) {
	tests := []struct {
		name string
		url  string
		want bool
	}{
		{"empty url", "", true},
		{"valid http", "http://example.com/file.jpg", true},
		{"valid https", "https://example.com/file.jpg", true},
		{"invalid scheme", "ftp://example.com/file.jpg", false},
		{"no host", "http:///file.jpg", false},
		{"relative path", "/path/to/file.jpg", false},
		{"random string", "not-a-url", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := profile.IsValidUploadURL(tt.url); got != tt.want {
				t.Errorf("IsValidUploadURL() = %v, want %v", got, tt.want)
			}
		})
	}
}
