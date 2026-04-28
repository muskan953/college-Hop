package tests

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/messages"
	"github.com/muskan953/college-Hop/internal/server"
)

// newMsgRouter is a helper that wires up a router with the given messages repo.
func newMsgRouter(t *testing.T, msgRepo messages.Repository) http.Handler {
	t.Helper()
	t.Setenv("JWT_SECRET", "testsecret")
	hub := messages.NewHub(msgRepo, nil)
	return server.NewRouter(
		&MockAuthRepository{}, nil, &MockProfileRepository{}, &MockAdminRepository{},
		&MockEventsRepository{}, &MockGroupsRepository{},
		msgRepo, hub, &MockFileStorage{}, "./uploads",
	)
}

// --- ListThreads ---

func TestListThreads_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("GET", "/messages/threads", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /messages/threads without auth: got %d, want 401", rr.Code)
	}
}

func TestListThreads_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		ListUserThreadsFunc: func(ctx context.Context, userID string) ([]messages.ThreadSummary, error) {
			return []messages.ThreadSummary{
				{ID: "thread-1", Name: "Test User"},
				{ID: "thread-2", Name: "Another User"},
			}, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("GET", "/messages/threads", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /messages/threads: got %d, want 200", rr.Code)
	}
	var result []messages.ThreadSummary
	json.NewDecoder(rr.Body).Decode(&result)
	if len(result) != 2 {
		t.Errorf("expected 2 threads, got %d", len(result))
	}
}

// --- GetMessages ---

func TestGetMessages_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("GET", "/messages/thread-1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("GET /messages/{id} without auth: got %d, want 401", rr.Code)
	}
}

func TestGetMessages_NotParticipant(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return false, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("GET", "/messages/thread-1", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusForbidden {
		t.Errorf("GET /messages/{id} non-participant: got %d, want 403", rr.Code)
	}
}

func TestGetMessages_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return true, nil
		},
		GetMessagesFunc: func(ctx context.Context, threadID, userID string, before time.Time, limit int) ([]messages.Message, error) {
			return []messages.Message{
				{ID: "msg-1", Content: "Hello"},
			}, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("GET", "/messages/thread-1", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("GET /messages/{id}: got %d, want 200", rr.Code)
	}
	var msgs []messages.Message
	json.NewDecoder(rr.Body).Decode(&msgs)
	if len(msgs) != 1 {
		t.Errorf("expected 1 message, got %d", len(msgs))
	}
}

// --- SendMessage ---

func TestSendMessage_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": "Hello"})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("POST /messages/send without auth: got %d, want 401", rr.Code)
	}
}

func TestSendMessage_EmptyContent(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": ""})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /messages/send empty content: got %d, want 400", rr.Code)
	}
}

func TestSendMessage_TooLongContent(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": strings.Repeat("a", 5005)})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /messages/send too-long content: got %d, want 400", rr.Code)
	}
}

func TestSendMessage_NotParticipant(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return false, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": "Hello"})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusForbidden {
		t.Errorf("POST /messages/send non-participant: got %d, want 403", rr.Code)
	}
}

func TestSendMessage_RequestLimitReached(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return true, nil
		},
		CreateMessageFunc: func(ctx context.Context, threadID, senderID, content string, replyToID *string, isForwarded bool) (messages.Message, error) {
			return messages.Message{}, sql.ErrNoRows // 10-message limit sentinel
		},
	}
	router := newMsgRouter(t, mockRepo)
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": "Hello"})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusTooManyRequests {
		t.Errorf("POST /messages/send at limit: got %d, want 429", rr.Code)
	}
}

func TestSendMessage_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return true, nil
		},
		CreateMessageFunc: func(ctx context.Context, threadID, senderID, content string, replyToID *string, isForwarded bool) (messages.Message, error) {
			return messages.Message{ID: "new-msg", Content: content}, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	body, _ := json.Marshal(map[string]string{"thread_id": "t1", "content": "Hello!"})
	req, _ := http.NewRequest("POST", "/messages/send", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusCreated {
		t.Errorf("POST /messages/send: got %d, want 201. Body: %s", rr.Code, rr.Body.String())
	}
}

// --- DeleteMessage ---

func TestDeleteMessage_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("DELETE", "/messages/msg-1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("DELETE /messages/{id} without auth: got %d, want 401", rr.Code)
	}
}

func TestDeleteMessage_NotOwner(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		DeleteMessageFunc: func(ctx context.Context, messageID, userID string) (string, error) {
			return "", sql.ErrNoRows
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("DELETE", "/messages/msg-1", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusNotFound {
		t.Errorf("DELETE /messages/{id} not owner: got %d, want 404", rr.Code)
	}
}

func TestDeleteMessage_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("DELETE", "/messages/msg-1", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusNoContent {
		t.Errorf("DELETE /messages/{id}: got %d, want 204", rr.Code)
	}
}

// --- GetOrCreateDirectThread ---

func TestGetOrCreateDirectThread_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"user_id": "user-2"})
	req, _ := http.NewRequest("POST", "/messages/thread/direct", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("POST /messages/thread/direct without auth: got %d, want 401", rr.Code)
	}
}

func TestGetOrCreateDirectThread_SelfThread(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	// Same user ID as the authenticated user
	body, _ := json.Marshal(map[string]string{"user_id": "user-1"})
	req, _ := http.NewRequest("POST", "/messages/thread/direct", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /messages/thread/direct same user: got %d, want 400", rr.Code)
	}
}

func TestGetOrCreateDirectThread_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"user_id": "user-2"})
	req, _ := http.NewRequest("POST", "/messages/thread/direct", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusCreated {
		t.Errorf("POST /messages/thread/direct: got %d, want 201. Body: %s", rr.Code, rr.Body.String())
	}
}

// --- ClearThread ---

func TestClearThread_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/clear", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("POST /messages/threads/{id}/clear without auth: got %d, want 401", rr.Code)
	}
}

func TestClearThread_NotParticipant(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return false, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("POST", "/messages/threads/t1/clear", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusForbidden {
		t.Errorf("POST /messages/threads/{id}/clear non-participant: got %d, want 403", rr.Code)
	}
}

func TestClearThread_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/clear", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /messages/threads/{id}/clear: got %d, want 200", rr.Code)
	}
}

// --- AcceptRequest ---

func TestAcceptRequest_RequiresAuth(t *testing.T) {
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/accept", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Errorf("POST /messages/threads/{id}/accept without auth: got %d, want 401", rr.Code)
	}
}

func TestAcceptRequest_NotParticipant(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	mockRepo := &MockMessagesRepository{
		IsParticipantFunc: func(ctx context.Context, threadID, userID string) (bool, error) {
			return false, nil
		},
	}
	router := newMsgRouter(t, mockRepo)
	req, _ := http.NewRequest("POST", "/messages/threads/t1/accept", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusForbidden {
		t.Errorf("POST /messages/threads/{id}/accept non-participant: got %d, want 403", rr.Code)
	}
}

func TestAcceptRequest_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/accept", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /messages/threads/{id}/accept: got %d, want 200", rr.Code)
	}
}

// --- DeclineRequest ---

func TestDeclineRequest_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/decline", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /messages/threads/{id}/decline: got %d, want 200", rr.Code)
	}
}

// --- MarkRead ---

func TestMarkRead_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	req, _ := http.NewRequest("POST", "/messages/threads/t1/read", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /messages/threads/{id}/read: got %d, want 200", rr.Code)
	}
}

// --- RegisterDeviceToken ---

func TestRegisterDeviceToken_MissingToken(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"token": "", "platform": "android"})
	req, _ := http.NewRequest("POST", "/me/device-token", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Errorf("POST /me/device-token missing token: got %d, want 400", rr.Code)
	}
}

func TestRegisterDeviceToken_Success(t *testing.T) {
	token, _ := auth.GenerateToken("user-1", "student@nitw.ac.in")
	router := newMsgRouter(t, &MockMessagesRepository{})
	body, _ := json.Marshal(map[string]string{"token": "fcm-abc-123", "platform": "android"})
	req, _ := http.NewRequest("POST", "/me/device-token", bytes.NewBuffer(body))
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("POST /me/device-token: got %d, want 200", rr.Code)
	}
}
