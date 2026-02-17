package main

import (
	"log"
	"net/http"
	"os"

	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/profile"
	"github.com/muskan953/college-Hop/internal/server"
	"github.com/muskan953/college-Hop/pkg/db"
	"github.com/muskan953/college-Hop/pkg/migrations"
	"github.com/muskan953/college-Hop/pkg/storage"
)

func main() {
	database, err := db.Connect()
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}

	defer database.Close()
	log.Println("Database connection established")
	if err := migrations.Run(database); err != nil {
		log.Fatalf("migration failed: %v", err)
	}

	log.Println("database migrations applied")

	// Initialize file storage
	uploadDir := os.Getenv("UPLOAD_DIR")
	if uploadDir == "" {
		uploadDir = "./uploads"
	}
	baseURL := os.Getenv("UPLOAD_BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080/uploads"
	}

	store, err := storage.NewLocalStorage(uploadDir, baseURL)
	if err != nil {
		log.Fatalf("failed to initialize storage: %v", err)
	}

	authRepo := auth.NewRepository(database)
	profileRepo := profile.NewRepository(database)

	mux := server.NewRouter(authRepo, profileRepo, store, uploadDir)

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
