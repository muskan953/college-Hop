package main

import (
	"log"
	"net/http"

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

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
