package messages

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/muskan953/college-Hop/internal/auth"
)

// Handler provides HTTP handlers for REST messaging endpoints.
type Handler struct {
	repo Repository
	hub  *Hub
}

// NewHandler creates a new Handler.
func NewHandler(repo Repository, hub *Hub) *Handler {
	return &Handler{
		repo: repo,
		hub:  hub,
	}
}

// GET /messages/threads — List all threads for the authenticated user.
func (h *Handler) ListThreads(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	threads, err := h.repo.ListUserThreads(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to list threads", http.StatusInternalServerError)
		return
	}
	if threads == nil {
		threads = []ThreadSummary{}
	}

	// Add live online status for direct threads
	for i := range threads {
		if threads[i].OtherUserID != nil {
			threads[i].IsOnline = h.hub.IsOnline(*threads[i].OtherUserID)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(threads)
}

// GET /messages/{threadId} — Get paginated messages for a thread.
func (h *Handler) GetMessages(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract threadID from URL: /messages/{threadId}
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 2 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	threadID := parts[1]

	// Check participation
	ok, err := h.repo.IsParticipant(r.Context(), threadID, user.ID)
	if err != nil || !ok {
		http.Error(w, "not a participant", http.StatusForbidden)
		return
	}

	// Parse pagination params
	before := time.Now()
	if beforeStr := r.URL.Query().Get("before"); beforeStr != "" {
		if t, err := time.Parse(time.RFC3339, beforeStr); err == nil {
			before = t
		}
	}
	limit := 50

	msgs, err := h.repo.GetMessages(r.Context(), threadID, user.ID, before, limit)
	if err != nil {
		http.Error(w, "failed to get messages", http.StatusInternalServerError)
		return
	}
	if msgs == nil {
		msgs = []Message{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msgs)
}

// POST /messages — Send a message (HTTP fallback when WS is unavailable).
func (h *Handler) SendMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req SendMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if err := ValidateContent(req.Content); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Check participation
	ok, err := h.repo.IsParticipant(r.Context(), req.ThreadID, user.ID)
	if err != nil || !ok {
		http.Error(w, "not a participant", http.StatusForbidden)
		return
	}

	// Check blocks
	participants, err := h.repo.GetParticipantIDs(r.Context(), req.ThreadID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	for _, pid := range participants {
		if pid == user.ID {
			continue
		}
		if blocked, _ := h.repo.IsBlocked(r.Context(), user.ID, pid); blocked {
			http.Error(w, "cannot send message to this user", http.StatusForbidden)
			return
		}
	}

	msg, err := h.repo.CreateMessage(r.Context(), req.ThreadID, user.ID, req.Content, req.ReplyToID, req.IsForwarded)
	if err != nil {
		http.Error(w, "failed to send message", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(msg)
}

// POST /messages/thread/direct — Get or create a 1:1 direct thread.
func (h *Handler) GetOrCreateDirectThread(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateDirectThreadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.UserID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	if req.UserID == user.ID {
		http.Error(w, "cannot create thread with yourself", http.StatusBadRequest)
		return
	}

	// Check blocks
	if blocked, _ := h.repo.IsBlocked(r.Context(), user.ID, req.UserID); blocked {
		http.Error(w, "cannot message this user", http.StatusForbidden)
		return
	}

	thread, err := h.repo.GetOrCreateDirectThread(r.Context(), user.ID, req.UserID)
	if err != nil {
		http.Error(w, "failed to create thread", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(thread)
}

// DELETE /messages/{messageId} — Delete own message.
func (h *Handler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 2 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	messageID := parts[1]

	threadID, err := h.repo.DeleteMessage(r.Context(), messageID, user.ID)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "message not found or not yours", http.StatusNotFound)
			return
		}
		http.Error(w, "failed to delete message", http.StatusInternalServerError)
		return
	}

	// Notify the Hub to push real-time deletion events
	h.hub.BroadcastMessageDeleted(r.Context(), threadID, messageID)

	w.WriteHeader(http.StatusNoContent)
}

// POST /messages/threads/{id}/clear — Clear chat for the authenticated user.
func (h *Handler) ClearThread(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// /messages/threads/{id}/clear
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 4 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	threadID := parts[2]

	ok, err := h.repo.IsParticipant(r.Context(), threadID, user.ID)
	if err != nil || !ok {
		http.Error(w, "not a participant", http.StatusForbidden)
		return
	}

	if err := h.repo.ClearThread(r.Context(), threadID, user.ID); err != nil {
		http.Error(w, "failed to clear chat", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "chat cleared"})
}

// POST /messages/threads/{id}/read — Mark a chat as read.
func (h *Handler) HandleMarkRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) < 4 {
		http.Error(w, "invalid URL", http.StatusBadRequest)
		return
	}
	threadID := parts[2]

	if err := h.repo.MarkThreadAsRead(r.Context(), threadID, user.ID); err != nil {
		http.Error(w, "failed to mark as read", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// POST /me/device-token — Register a device token for push notifications.
func (h *Handler) RegisterDeviceToken(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		Token    string `json:"token"`
		Platform string `json:"platform"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Token == "" {
		http.Error(w, "token is required", http.StatusBadRequest)
		return
	}
	if req.Platform == "" {
		req.Platform = "android"
	}

	if err := h.repo.UpsertDeviceToken(r.Context(), user.ID, req.Token, req.Platform); err != nil {
		http.Error(w, "failed to register token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "token registered"})
}
