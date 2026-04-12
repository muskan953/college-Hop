package messages

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/muskan953/college-Hop/internal/auth"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for dev; restrict in production
	},
}

// ServeWS handles WebSocket upgrade requests.
// Auth is done via JWT passed as query param: /ws?token=xxx
func ServeWS(hub *Hub) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 1. Validate JWT from query parameter
		token := r.URL.Query().Get("token")
		if token == "" {
			http.Error(w, "missing token", http.StatusUnauthorized)
			return
		}

		claims, err := auth.ParseToken(token)
		if err != nil {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		userID := claims.UserID

		// 2. Upgrade HTTP → WebSocket
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("[WS] Upgrade failed for user %s: %v", userID, err)
			return
		}

		// 3. Create client and register with hub
		client := &Client{
			hub:    hub,
			conn:   conn,
			userID: userID,
			send:   make(chan []byte, 256),
		}
		hub.register <- client

		// 4. Start pumps in separate goroutines
		go client.writePump()
		go client.readPump()
	}
}
