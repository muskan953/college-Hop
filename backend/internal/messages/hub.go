package messages

import (
	"context"
	"encoding/json"
	"log"
	"sync"

	"github.com/muskan953/college-Hop/pkg/notify"
)

// Hub maintains the set of active clients and broadcasts messages to them.
type Hub struct {
	// Registered clients keyed by user ID.
	clients map[string]*Client

	// Inbound messages from clients.
	broadcast chan *broadcastMsg

	// Register requests from clients.
	register chan *Client

	// Unregister requests from clients.
	unregister chan *Client

	mu       sync.RWMutex
	repo     Repository
	notifier *notify.Notifier
}

// broadcastMsg carries a message plus sender context through the hub.
type broadcastMsg struct {
	senderID string
	incoming WSIncoming
}

// NewHub creates a new Hub.
func NewHub(repo Repository, notifier *notify.Notifier) *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		broadcast:  make(chan *broadcastMsg, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		repo:       repo,
		notifier:   notifier,
	}
}

// Run starts the hub's main event loop. This should be started as a goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			// Close existing connection for same user (single-device)
			if existing, ok := h.clients[client.userID]; ok {
				close(existing.send)
				delete(h.clients, client.userID)
			}
			h.clients[client.userID] = client
			h.mu.Unlock()
			log.Printf("[Hub] Client registered: %s", client.userID)

		case client := <-h.unregister:
			h.mu.Lock()
			if existing, ok := h.clients[client.userID]; ok && existing == client {
				close(existing.send)
				delete(h.clients, client.userID)
			}
			h.mu.Unlock()
			log.Printf("[Hub] Client unregistered: %s", client.userID)

		case bMsg := <-h.broadcast:
			h.handleBroadcast(bMsg)
		}
	}
}

// IsOnline checks if a user has an active WebSocket connection.
func (h *Hub) IsOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

// handleBroadcast processes an incoming message from a client.
func (h *Hub) handleBroadcast(bMsg *broadcastMsg) {
	ctx := context.Background()

	switch bMsg.incoming.Type {
	case "message":
		h.handleMessage(ctx, bMsg)
	case "typing":
		h.handleTyping(ctx, bMsg)
	default:
		log.Printf("[Hub] Unknown message type: %s", bMsg.incoming.Type)
	}
}

// handleMessage persists a message and delivers it to thread participants.
func (h *Hub) handleMessage(ctx context.Context, bMsg *broadcastMsg) {
	threadID := bMsg.incoming.ThreadID
	senderID := bMsg.senderID
	content := bMsg.incoming.Content

	// Validate content
	if err := ValidateContent(content); err != nil {
		h.sendError(senderID, err.Error())
		return
	}

	// Check participation
	ok, err := h.repo.IsParticipant(ctx, threadID, senderID)
	if err != nil || !ok {
		h.sendError(senderID, "not a participant of this thread")
		return
	}

	// Get participants to check blocks
	participants, err := h.repo.GetParticipantIDs(ctx, threadID)
	if err != nil {
		h.sendError(senderID, "internal error")
		return
	}

	// Check if sender is blocked by any participant (for direct chats)
	for _, pid := range participants {
		if pid == senderID {
			continue
		}
		blocked, _ := h.repo.IsBlocked(ctx, senderID, pid)
		if blocked {
			h.sendError(senderID, "cannot send message to this user")
			return
		}
	}

	// Persist the message
	msg, err := h.repo.CreateMessage(ctx, threadID, senderID, content)
	if err != nil {
		log.Printf("[Hub] Failed to persist message: %v", err)
		h.sendError(senderID, "failed to send message")
		return
	}

	// Send confirmation to sender
	h.sendToUser(senderID, WSOutgoing{
		Type:    "message_sent",
		Payload: WSMessageSent{MessageID: msg.ID, ThreadID: msg.ThreadID},
	})

	// Deliver to all other participants (online via WS, offline via push)
	newMsgPayload := WSOutgoing{
		Type:    "new_message",
		Payload: WSNewMessage{Message: msg},
	}
	for _, pid := range participants {
		if pid == senderID {
			continue
		}
		if h.IsOnline(pid) {
			h.sendToUser(pid, newMsgPayload)
		} else {
			// User is offline — send push notification
			go h.sendPushNotification(ctx, pid, msg)
		}
	}
}

// handleTyping broadcasts typing indicators to other thread participants.
func (h *Hub) handleTyping(ctx context.Context, bMsg *broadcastMsg) {
	threadID := bMsg.incoming.ThreadID
	senderID := bMsg.senderID

	participants, err := h.repo.GetParticipantIDs(ctx, threadID)
	if err != nil {
		return
	}

	// We need the sender's name for the typing indicator
	typing := WSOutgoing{
		Type: "user_typing",
		Payload: WSUserTyping{
			ThreadID: threadID,
			UserID:   senderID,
			UserName: "", // filled by client-side from cached participant info
		},
	}

	for _, pid := range participants {
		if pid == senderID {
			continue
		}
		h.sendToUser(pid, typing)
	}
}

// sendToUser sends a WSOutgoing message to a specific user if they're online.
func (h *Hub) sendToUser(userID string, msg WSOutgoing) {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return // user is offline
	}

	data, err := json.Marshal(msg)
	if err != nil {
		return
	}

	select {
	case client.send <- data:
	default:
		// Client send buffer full, skip
		log.Printf("[Hub] Send buffer full for user %s, dropping message", userID)
	}
}

// sendError sends an error message to a specific user.
func (h *Hub) sendError(userID string, errMsg string) {
	h.sendToUser(userID, WSOutgoing{
		Type:    "error",
		Payload: map[string]string{"message": errMsg},
	})
}

// sendPushNotification sends a push notification to an offline user.
func (h *Hub) sendPushNotification(ctx context.Context, userID string, msg Message) {
	if h.notifier == nil {
		return
	}

	tokens, err := h.repo.GetDeviceTokens(ctx, userID)
	if err != nil || len(tokens) == 0 {
		return
	}

	// Truncate content for notification body
	body := msg.Content
	if len(body) > 100 {
		body = body[:97] + "..."
	}

	data := map[string]string{
		"type":      "new_message",
		"thread_id": msg.ThreadID,
		"sender_id": msg.SenderID,
	}

	h.notifier.SendToMany(ctx, tokens, msg.SenderName, body, data)
}

