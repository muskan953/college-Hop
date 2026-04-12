package messages

import "errors"

var (
	ErrContentTooLong = errors.New("message content exceeds 5000 characters")
	ErrContentEmpty   = errors.New("message content is empty")
	ErrNotParticipant = errors.New("user is not a participant of this thread")
	ErrBlocked        = errors.New("user is blocked")
)

// ValidateContent checks message content constraints.
func ValidateContent(content string) error {
	if len(content) == 0 {
		return ErrContentEmpty
	}
	if len(content) > 5000 {
		return ErrContentTooLong
	}
	return nil
}
