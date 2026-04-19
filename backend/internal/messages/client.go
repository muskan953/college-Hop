package messages

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer (8 KB).
	maxMessageSize = 8192

	// Rate limit: max messages per minute.
	maxMsgsPerMinute = 30
)

// Client is a middleman between the WebSocket connection and the Hub.
type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	userID string

	// Buffered channel of outbound messages.
	send chan []byte

	// Rate limiting
	msgCount  int
	rateReset time.Time
}

// readPump pumps messages from the WebSocket connection to the Hub.
// Runs in its own goroutine per connection.
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	c.rateReset = time.Now().Add(time.Minute)

	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			log.Printf("[Client] Read error for %s: %v", c.userID, err)
			break
		}

		// Rate limiting
		if time.Now().After(c.rateReset) {
			c.msgCount = 0
			c.rateReset = time.Now().Add(time.Minute)
		}
		c.msgCount++
		if c.msgCount > maxMsgsPerMinute {
			log.Printf("[Client] Rate limit exceeded for %s, disconnecting", c.userID)
			break
		}

		// Parse the incoming message
		var incoming WSIncoming
		if err := json.Unmarshal(data, &incoming); err != nil {
			log.Printf("[Client] Invalid JSON from %s: %v", c.userID, err)
			continue
		}

		c.hub.broadcast <- &broadcastMsg{
			senderID: c.userID,
			incoming: incoming,
		}
	}
}

// writePump pumps messages from the Hub to the WebSocket connection.
// Runs in its own goroutine per connection.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Hub closed the channel.
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
