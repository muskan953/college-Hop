package server

import (
	"net/http"
	"strings"

	"github.com/muskan953/college-Hop/internal/admin"
	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/events"
	"github.com/muskan953/college-Hop/internal/groups"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/internal/upload"
	"github.com/muskan953/college-Hop/pkg/storage"
)

func NewRouter(authRepo auth.Repository, profileRepo profile.Repository, adminRepo admin.Repository, eventsRepo events.Repository, groupsRepo groups.Repository, store storage.FileStorage, uploadDir string) *http.ServeMux {
	mux := http.NewServeMux()

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

	profileHandler := profile.NewHandler(profileRepo)

	mux.Handle("/me", auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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

	// Upload route (protected by auth)
	uploadHandler := upload.NewHandler(store)
	mux.Handle("/upload", auth.AuthMiddleware(http.HandlerFunc(uploadHandler.Upload)))

	// Serve uploaded files
	// Profile photos are public
	mux.Handle("/uploads/profile_photo/", http.StripPrefix("/uploads", upload.ServeFile(uploadDir)))
	// ID cards are private (require authentication)
	mux.Handle("/uploads/id_card/", auth.AuthMiddleware(http.StripPrefix("/uploads", upload.ServeFile(uploadDir))))

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
		auth.AuthMiddleware(http.HandlerFunc(eventsHandler.CreateEvent)).ServeHTTP(w, r)
	})

	// Protected: set/get user's selected event
	mux.Handle("/me/event", auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
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
	groupsHandler := groups.NewHandler(groupsRepo)

	// Protected: suggested groups
	mux.Handle("/groups/suggested", auth.AuthMiddleware(http.HandlerFunc(groupsHandler.SuggestedGroups)))

	// Protected: create group
	mux.Handle("/groups", auth.AuthMiddleware(http.HandlerFunc(groupsHandler.CreateGroup)))

	// Protected: join group (/groups/{id}/join)
	mux.Handle("/groups/", auth.AuthMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/join") {
			groupsHandler.JoinGroup(w, r)
			return
		}
		http.Error(w, "not found", http.StatusNotFound)
	})))

	// Protected: peer matching
	mux.Handle("/users/matches", auth.AuthMiddleware(http.HandlerFunc(groupsHandler.FindMatches)))

	return mux
}
