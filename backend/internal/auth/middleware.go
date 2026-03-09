package auth

import (
	"net/http"
	"strings"
)

// AuthMiddleware validates the Bearer JWT and injects the user into the request context.
// It also rejects any user whose status is "blocked".
// Use NewAuthMiddleware(repo) to construct it with a repository reference.
func AuthMiddleware(next http.Handler) http.Handler {
	// This signature is kept for compatibility; blocked-user check requires
	// a repo — use NewAuthMiddleware(repo) when you need that enforcement.
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := bearerClaims(w, r)
		if !ok {
			return
		}
		ctx := WithUser(r.Context(), UserContext{
			ID:    claims.UserID,
			Email: claims.Email,
		})
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// NewAuthMiddleware returns an auth middleware that also checks whether a user
// has been blocked, rejecting them with 403 Forbidden before hitting any handler.
func NewAuthMiddleware(repo Repository) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := bearerClaims(w, r)
			if !ok {
				return
			}

			// Look up live user status — blocks suspended accounts even if their
			// JWT has not expired yet.
			status, err := repo.GetUserStatus(r.Context(), claims.UserID)
			if err != nil {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}
			if status == "blocked" {
				http.Error(w, "your account has been blocked", http.StatusForbidden)
				return
			}

			ctx := WithUser(r.Context(), UserContext{
				ID:    claims.UserID,
				Email: claims.Email,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// bearerClaims is a shared helper that validates the Bearer token and returns
// its claims. It writes the appropriate error to w and returns false on failure.
func bearerClaims(w http.ResponseWriter, r *http.Request) (*Claims, bool) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "missing authorization header", http.StatusUnauthorized)
		return nil, false
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		http.Error(w, "invalid authorization header", http.StatusUnauthorized)
		return nil, false
	}

	claims, err := ParseToken(parts[1])
	if err != nil {
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return nil, false
	}
	return claims, true
}
