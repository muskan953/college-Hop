package middleware

import (
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// visitor tracks the rate limiter and last seen time for a single IP.
type visitor struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// RateLimiter is an in-memory, per-IP rate limiter.
type RateLimiter struct {
	mu       sync.RWMutex
	visitors map[string]*visitor
	rate     rate.Limit
	burst    int
}

// NewRateLimiter creates a new rate limiter.
// r is requests per second, b is the burst size.
func NewRateLimiter(r rate.Limit, b int) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		rate:     r,
		burst:    b,
	}

	// Background goroutine to clean up stale entries every 3 minutes.
	go rl.cleanup()

	return rl
}

func (rl *RateLimiter) getVisitor(ip string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	v, exists := rl.visitors[ip]
	if !exists {
		limiter := rate.NewLimiter(rl.rate, rl.burst)
		rl.visitors[ip] = &visitor{limiter: limiter, lastSeen: time.Now()}
		return limiter
	}

	v.lastSeen = time.Now()
	return v.limiter
}

func (rl *RateLimiter) cleanup() {
	for {
		time.Sleep(3 * time.Minute)

		rl.mu.Lock()
		for ip, v := range rl.visitors {
			if time.Since(v.lastSeen) > 3*time.Minute {
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}

// realIP extracts the actual client IP from the request.
// It checks X-Forwarded-For first (set by reverse proxies like nginx / Render),
// then X-Real-IP, and finally falls back to stripping the port from RemoteAddr.
func realIP(r *http.Request) string {
	// X-Forwarded-For may contain a comma-separated list; the first entry is the client.
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		// Take only the first IP in the list
		for i := 0; i < len(xff); i++ {
			if xff[i] == ',' {
				return xff[:i]
			}
		}
		return xff
	}
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr — strip the port (e.g. "1.2.3.4:54321" → "1.2.3.4")
	addr := r.RemoteAddr
	for i := len(addr) - 1; i >= 0; i-- {
		if addr[i] == ':' {
			return addr[:i]
		}
	}
	return addr
}

// Limit is the middleware handler.
func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := realIP(r)

		limiter := rl.getVisitor(ip)
		if !limiter.Allow() {
			http.Error(w, "too many requests", http.StatusTooManyRequests)
			return
		}

		next.ServeHTTP(w, r)
	})
}
