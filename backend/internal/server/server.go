package server

import (
	"net/http"
	"strings"

	"github.com/muskan953/college-Hop/internal/admin"
	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/events"
	"github.com/muskan953/college-Hop/internal/groups"
	"github.com/muskan953/college-Hop/internal/messages"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/internal/upload"
	"github.com/muskan953/college-Hop/pkg/storage"
)

func NewRouter(authRepo auth.Repository, profileRepo profile.Repository, adminRepo admin.Repository, eventsRepo events.Repository, groupsRepo groups.Repository, messagesRepo messages.Repository, hub *messages.Hub, store storage.FileStorage, uploadDir string) *http.ServeMux {
	mux := http.NewServeMux()

	// authMW is the full auth middleware: validates JWT + rejects blocked users.
	authMW := auth.NewAuthMiddleware(authRepo)

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	authHandler := auth.NewHandler(authRepo)

	mux.HandleFunc("/auth/signup", authHandler.Signup)
	mux.HandleFunc("/auth/login", authHandler.Login)
	mux.HandleFunc("/auth/verify", authHandler.Verify)
	mux.HandleFunc("/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("/auth/logout", authHandler.Logout)

	profileHandler := profile.NewHandler(profileRepo, authRepo, messagesRepo)

	mux.Handle("/me", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			profileHandler.GetMe(w, r)
			return
		}
		if r.Method == http.MethodPut {
			profileHandler.UpdateMe(w, r)
			return
		}
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	})))

	mux.Handle("/me/preferences", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			profileHandler.GetPreferences(w, r)
			return
		}
		if r.Method == http.MethodPut {
			profileHandler.UpdatePreferences(w, r)
			return
		}
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	})))

	// Protected: alternate email verification
	mux.Handle("/me/alternate-email/request-otp", authMW(http.HandlerFunc(profileHandler.RequestAlternateEmailOTP)))
	mux.Handle("/me/alternate-email/verify", authMW(http.HandlerFunc(profileHandler.VerifyAlternateEmail)))

	// Protected: get user connections
	mux.Handle("/me/connections", authMW(http.HandlerFunc(profileHandler.GetConnections)))

	// Protected: get blocked users list
	mux.Handle("/me/blocked", authMW(http.HandlerFunc(profileHandler.GetBlockedUsers)))

	// Upload route (protected by auth)
	uploadHandler := upload.NewHandler(store)
	mux.Handle("/upload", authMW(http.HandlerFunc(uploadHandler.Upload)))

	// Serve uploaded files
	// Profile photos are public
	mux.Handle("/uploads/profile_photo/", http.StripPrefix("/uploads", upload.ServeFile(uploadDir)))
	// ID cards are private (require authentication)
	mux.Handle("/uploads/id_card/", authMW(http.StripPrefix("/uploads", upload.ServeFile(uploadDir))))

	// Admin routes (protected by admin secret)
	adminHandler := admin.NewHandler(adminRepo)
	mux.Handle("/admin/users/pending", admin.AdminAuth(http.HandlerFunc(adminHandler.ListPendingUsers)))
	mux.Handle("/admin/users/", admin.AdminAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Route: /admin/users/{id}/verify or /admin/users/{id}/block
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		path := r.URL.Path
		if len(path) > 0 && path[len(path)-1] == '/' {
			path = path[:len(path)-1]
		}
		if len(path) > 7 && path[len(path)-7:] == "/verify" {
			adminHandler.VerifyUser(w, r)
			return
		}
		if len(path) > 6 && path[len(path)-6:] == "/block" {
			adminHandler.BlockUser(w, r)
			return
		}
		http.Error(w, "not found", http.StatusNotFound)
	})))

	// --- Events routes ---
	eventsHandler := events.NewHandler(eventsRepo)

	// Public: list approved events
	mux.HandleFunc("/events", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			eventsHandler.ListEvents(w, r)
			return
		}
		// Protected: create event (any auth user)
		authMW(http.HandlerFunc(eventsHandler.CreateEvent)).ServeHTTP(w, r)
	})

	// Protected: set/get user's selected event
	mux.Handle("/me/event", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPut {
			eventsHandler.SetUserEvent(w, r)
			return
		}
		if r.Method == http.MethodGet {
			eventsHandler.GetUserEvent(w, r)
			return
		}
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	})))

	// Protected: get all user events
	mux.Handle("/me/events", authMW(http.HandlerFunc(eventsHandler.GetUserEvents)))

	// Admin: pending events + approve/reject
	mux.Handle("/admin/events/pending", admin.AdminAuth(http.HandlerFunc(eventsHandler.ListPendingEvents)))
	mux.Handle("/admin/events/", admin.AdminAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if strings.HasSuffix(path, "/approve") {
			eventsHandler.ApproveEvent(w, r)
			return
		}
		if strings.HasSuffix(path, "/reject") {
			eventsHandler.RejectEvent(w, r)
			return
		}
		http.Error(w, "not found", http.StatusNotFound)
	})))

	// --- Groups routes ---
	groupsHandler := groups.NewHandler(groupsRepo, hub)

	// Protected: suggested groups
	mux.Handle("/groups/suggested", authMW(http.HandlerFunc(groupsHandler.SuggestedGroups)))

	// Protected: get all groups the user belongs to
	mux.Handle("/me/groups", authMW(http.HandlerFunc(groupsHandler.GetMyGroups)))

	// Protected: create group or list all groups
	mux.Handle("/groups", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			groupsHandler.ListAllGroups(w, r)
			return
		}
		if r.Method == http.MethodPost {
			groupsHandler.CreateGroup(w, r)
			return
		}
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	})))

	// Protected: group detail, update, delete, join, leave, kick (/groups/{id}/...)
	mux.Handle("/groups/", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		switch {
		case strings.HasSuffix(path, "/join") && r.Method == http.MethodPost:
			groupsHandler.JoinGroup(w, r)
		case strings.HasSuffix(path, "/leave") && r.Method == http.MethodPost:
			groupsHandler.LeaveGroup(w, r)
		case strings.HasSuffix(path, "/kick") && r.Method == http.MethodPost:
			groupsHandler.KickMember(w, r)
		case r.Method == http.MethodGet:
			groupsHandler.GetGroup(w, r)
		case r.Method == http.MethodPut:
			groupsHandler.UpdateGroup(w, r)
		case r.Method == http.MethodDelete:
			groupsHandler.DeleteGroup(w, r)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
	})))

	// Protected: peer matching
	mux.Handle("/users/matches", authMW(http.HandlerFunc(groupsHandler.FindMatches)))

	// Protected: view any user's profile GET /users/{id} — requires auth so
	// profiles can't be viewed outside the app.
	mux.Handle("/users/", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		switch {
		case strings.HasSuffix(path, "/connect") && r.Method == http.MethodPost:
			profileHandler.ConnectUser(w, r)
		case strings.HasSuffix(path, "/block") && r.Method == http.MethodPost:
			profileHandler.BlockUser(w, r)
		case strings.HasSuffix(path, "/unblock") && r.Method == http.MethodPost:
			profileHandler.UnblockUser(w, r)
		case r.Method == http.MethodGet:
			profileHandler.GetPublicProfile(w, r)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
	})))

	// --- Messages routes ---
	msgHandler := messages.NewHandler(messagesRepo, hub)

	// Protected: list threads
	mux.Handle("/messages/threads", authMW(http.HandlerFunc(msgHandler.ListThreads)))

	// Protected: get-or-create direct thread
	mux.Handle("/messages/thread/direct", authMW(http.HandlerFunc(msgHandler.GetOrCreateDirectThread)))

	// Protected: send message (HTTP fallback)
	mux.Handle("/messages/send", authMW(http.HandlerFunc(msgHandler.SendMessage)))

	// Protected: clear chat, get messages, delete message
	mux.Handle("/messages/", authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		switch {
		case strings.HasSuffix(path, "/clear") && r.Method == http.MethodPost:
			msgHandler.ClearThread(w, r)
		case strings.HasSuffix(path, "/read") && r.Method == http.MethodPost:
			msgHandler.HandleMarkRead(w, r)
		case strings.HasSuffix(path, "/accept") && r.Method == http.MethodPost:
			msgHandler.AcceptRequest(w, r)
		case strings.HasSuffix(path, "/decline") && r.Method == http.MethodPost:
			msgHandler.DeclineRequest(w, r)
		case r.Method == http.MethodGet:
			msgHandler.GetMessages(w, r)
		case r.Method == http.MethodDelete:
			msgHandler.DeleteMessage(w, r)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
	})))

	// Protected: register device token for push notifications
	mux.Handle("/me/device-token", authMW(http.HandlerFunc(msgHandler.RegisterDeviceToken)))

	// WebSocket endpoint (auth via query param, not middleware)
	mux.HandleFunc("/ws", messages.ServeWS(hub))

	return mux
}
