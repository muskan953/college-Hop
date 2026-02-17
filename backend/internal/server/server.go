package server

import (
	"net/http"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/internal/upload"
	"github.com/muskan953/college-Hop/pkg/storage"
)

func NewRouter(authRepo auth.Repository, profileRepo profile.Repository, store storage.FileStorage, uploadDir string) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	authHandler := auth.NewHandler(authRepo)

	mux.HandleFunc("/auth/signup", authHandler.Signup)
	mux.HandleFunc("/auth/verify", authHandler.Verify)

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
	mux.Handle("/uploads/", http.StripPrefix("/uploads", upload.ServeFile(uploadDir)))

	return mux
}
