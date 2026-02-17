package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/muskan953/college-Hop/internal/admin"
	"github.com/muskan953/college-Hop/internal/auth"
	"github.com/muskan953/college-Hop/internal/middleware"
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
	adminRepo := admin.NewRepository(database)

	mux := server.NewRouter(authRepo, profileRepo, adminRepo, store, uploadDir)

	// Wrap with rate limiter: 20 requests/sec, burst of 40
	limiter := middleware.NewRateLimiter(20, 40)
	handler := limiter.Limit(mux)
	handler = middleware.Cors(handler)

	srv := &http.Server{
		Addr:         ":8080",
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Println("Server running on :8080")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Give outstanding requests 5 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited gracefully")
}
