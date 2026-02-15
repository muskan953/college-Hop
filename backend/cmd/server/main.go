package main

import (
	"log"
	"net/http"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/pkg/db"
	"github.com/muskan953/college-Hop/pkg/migrations"
)

func main() {
	database, err := db.Connect()
	if err != nil {
		log.Fatal("Database connection failed: %v", err)
	}

	defer database.Close()
	log.Println("Database connection established")
	if err := migrations.Run(database); err != nil {
		log.Fatalf("migration failed: %v", err)
	}

	log.Println("database migrations applied")

	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	authRepo := auth.NewRepository(database)
	authHandler := auth.NewHandler(authRepo)

	mux.HandleFunc("/auth/signup", authHandler.Signup)
	mux.HandleFunc("/auth/verify", authHandler.Verify)

	profileRepo := profile.NewRepository(database)
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

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
