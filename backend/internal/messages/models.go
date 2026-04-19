package messages

import "time"

// Thread represents a conversation container (direct or group).
type Thread struct {
	ID                  string    `json:"id"`
	Type                string    `json:"type"`     // "direct" or "group"
	GroupID             *string   `json:"group_id"` // nil for direct
	CreatedAt           time.Time `json:"created_at"`
	IsRequest           bool      `json:"is_request"`
	RequestMessageCount int       `json:"request_message_count"`
}

// ThreadSummary is returned by ListUserThreads for the thread list screen.
type ThreadSummary struct {
	ID              string    `json:"id"`
	Type            string    `json:"thread_type"`
	GroupID         *string   `json:"group_id"`
	Name            string    `json:"name"`
	LastMessage     string    `json:"last_message"`
	LastMessageTime time.Time `json:"last_message_at"`
	AvatarURL       *string   `json:"avatar_url"`
	Participants        []string  `json:"participant_ids"`
	OtherUserID         *string   `json:"other_user_id"`
	OtherUserName       string    `json:"other_user_name"`
	UnreadCount         int       `json:"unread_count"`
	IsOnline            bool      `json:"is_online"`
	IsRequest           bool      `json:"is_request"`
	RequestMessageCount int       `json:"request_message_count"`
	IsRequester         bool      `json:"is_requester"`
}

// Message represents a single chat message.
type Message struct {
	ID              string    `json:"id"`
	ThreadID        string    `json:"thread_id"`
	SenderID        string    `json:"sender_id"`
	SenderName      string    `json:"sender_name"`
	Content         string    `json:"content"`
	CreatedAt       time.Time `json:"created_at"`
	ReplyToID       *string   `json:"reply_to_id,omitempty"`
	IsForwarded     bool      `json:"is_forwarded"`
	ReplyToContent  *string   `json:"reply_to_content,omitempty"`
	ReplyToSender   *string   `json:"reply_to_sender,omitempty"`
}

// --- Request DTOs ---

// SendMessageRequest is the payload for POST /messages and WS "message" type.
type SendMessageRequest struct {
	ThreadID    string  `json:"thread_id"`
	Content     string  `json:"content"`
	ReplyToID   *string `json:"reply_to_id,omitempty"`
	IsForwarded bool    `json:"is_forwarded"`
}

// CreateDirectThreadRequest is the payload for POST /messages/thread/direct.
type CreateDirectThreadRequest struct {
	UserID string `json:"user_id"`
}

// --- WebSocket Protocol ---

// WSIncoming represents a message received from a client over WebSocket.
type WSIncoming struct {
	Type        string  `json:"type"`      // "message", "typing"
	ThreadID    string  `json:"thread_id"` // target thread
	Content     string  `json:"content"`   // message body (for "message" type)
	ReplyToID   *string `json:"reply_to_id,omitempty"`
	IsForwarded bool    `json:"is_forwarded"`
}

// WSOutgoing represents a message sent to a client over WebSocket.
type WSOutgoing struct {
	Type    string      `json:"type"` // "new_message", "message_sent", "user_typing", "error"
	Payload interface{} `json:"payload,omitempty"`
}

// WSNewMessage is the payload for "new_message" events.
type WSNewMessage struct {
	Message
}

// WSMessageSent is the payload for "message_sent" confirmations.
type WSMessageSent struct {
	MessageID string `json:"message_id"`
	ThreadID  string `json:"thread_id"`
}

// WSUserTyping is the payload for "user_typing" events.
type WSUserTyping struct {
	ThreadID string `json:"thread_id"`
	UserID   string `json:"user_id"`
	UserName string `json:"user_name"`
}
