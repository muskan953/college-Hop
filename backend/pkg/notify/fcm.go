package notify

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// Notifier sends push notifications via Firebase Cloud Messaging.
type Notifier struct {
	client *messaging.Client
}

// New creates a new Notifier. Returns nil if Firebase credentials are not configured.
func New() *Notifier {
	credPath := os.Getenv("FIREBASE_CREDENTIALS_PATH")
	if credPath == "" {
		credPath = "firebase-service-account.json"
	}

	// Check if the credentials file exists
	if _, err := os.Stat(credPath); os.IsNotExist(err) {
		log.Println("[Notify] Firebase credentials not found, push notifications disabled")
		return nil
	}

	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credPath))
	if err != nil {
		log.Printf("[Notify] Failed to init Firebase: %v", err)
		return nil
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("[Notify] Failed to init FCM client: %v", err)
		return nil
	}

	log.Println("[Notify] Firebase Cloud Messaging initialized")
	return &Notifier{client: client}
}

// Send sends a push notification to a specific device token.
func (n *Notifier) Send(ctx context.Context, token, title, body string, data map[string]string) error {
	if n == nil || n.client == nil {
		return nil // silently skip if FCM not configured
	}

	msg := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				ChannelID: "messages",
				Sound:     "default",
			},
		},
	}

	_, err := n.client.Send(ctx, msg)
	if err != nil {
		return fmt.Errorf("fcm send: %w", err)
	}
	return nil
}

// SendToMany sends a push notification to multiple device tokens.
func (n *Notifier) SendToMany(ctx context.Context, tokens []string, title, body string, data map[string]string) {
	if n == nil || n.client == nil || len(tokens) == 0 {
		return
	}

	for _, token := range tokens {
		if err := n.Send(ctx, token, title, body, data); err != nil {
			log.Printf("[Notify] Failed to send to token: %v", err)
		}
	}
}
