package tests

import (
	"database/sql"
	"fmt"
	"os"
	"testing"

	_ "github.com/jackc/pgx/v5/stdlib"
)

var testDB *sql.DB

func TestMain(m *testing.M) {
	// 1. Connect to the running Docker database
	// Use environment variables or fallback to defaults matching docker-compose.yml
	dsn := os.Getenv("TEST_DB_DSN")
	if dsn == "" {
		dsn = "postgres://college_hop:college_hop@127.0.0.1:5433/college_hop?sslmode=disable"
	}

	var err error
	testDB, err = sql.Open("pgx", dsn)
	if err != nil {
		fmt.Printf("Failed to connect to database: %v\n", err)
		os.Exit(1)
	}

	if err := testDB.Ping(); err != nil {
		fmt.Printf("Failed to ping database: %v. Is Docker running?\n", err)
		os.Exit(1)
	}

	// 2. Run tests
	code := m.Run()

	// 3. Cleanup
	testDB.Close()

	os.Exit(code)
}

// Helper to clean tables between tests
func clearTables(t *testing.T, tables ...string) {
	for _, table := range tables {
		_, err := testDB.Exec("TRUNCATE TABLE " + table + " CASCADE")
		if err != nil {
			t.Fatalf("Failed to truncate table %s: %v", table, err)
		}
	}
}
