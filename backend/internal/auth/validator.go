package auth

import (
	"errors"
	"net/mail"
	"strings"
)

var (
	ErrInvalidEmail    = errors.New("invalid email format")
	ErrNonStudentEmail = errors.New("non-student email address")
)

// ValidateEmail checks syntax + student domain
func ValidateEmail(email string) error {
	// 1. Basic syntax validation
	parsed, err := mail.ParseAddress(email)
	if err != nil {
		return ErrInvalidEmail
	}

	domain := strings.Split(parsed.Address, "@")
	if len(domain) != 2 {
		return ErrInvalidEmail
	}

	emailDomain := strings.ToLower(domain[1])

	if !strings.Contains(emailDomain, ".") {
		return ErrInvalidEmail
	}
	// 2. Reject common personal email providers
	blockedDomains := map[string]bool{
		"gmail.com":   true,
		"yahoo.com":   true,
		"outlook.com": true,
		"hotmail.com": true,
		"zoho.com":    true,
	}

	if blockedDomains[emailDomain] {
		return ErrNonStudentEmail
	}

	return nil
}
