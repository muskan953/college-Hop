# College Hop — Backend

A production-ready **Go REST API + WebSocket server** for the College Hop platform. Built with Go's stdlib `net/http`, PostgreSQL via `pgx/v5`, and `gorilla/websocket`. No external HTTP framework.

---

## Tech Stack

| Component | Technology | Version |
|---|---|---|
| Language | Go | 1.25.4 |
| HTTP Router | `net/http.ServeMux` | stdlib |
| Database | PostgreSQL | 15 |
| DB Driver | `jackc/pgx/v5` | 5.8.0 |
| Migrations | `golang-migrate/v4` | 4.19.1 |
| JWT | `golang-jwt/v5` | 5.3.1 |
| WebSockets | `gorilla/websocket` | 1.5.3 |
| Push Notifications | Firebase Cloud Messaging (FCM) | v4.19.0 |
| Rate Limiting | `golang.org/x/time/rate` | — |
| Container | Docker + Docker Compose | — |

---

## Project Structure

```
backend/
├── cmd/server/               # main.go — entrypoint
├── internal/
│   ├── auth/                 # OTP, JWT, signup/login/verify/refresh/logout
│   ├── profile/              # GET/PUT /me, preferences, alternate email, connections
│   ├── events/               # Event CRUD, user-event selection
│   ├── groups/               # Travel groups, join/leave/kick, matching algorithm
│   ├── admin/                # User moderation, event approval
│   ├── messages/             # ⭐ WebSocket Hub + REST messaging handlers
│   │   ├── hub.go            # Single goroutine: presence, routing, broadcast
│   │   ├── client.go         # readPump + writePump per connection, rate limiting
│   │   ├── ws_handler.go     # WebSocket upgrade + JWT auth
│   │   ├── handler.go        # REST handlers
│   │   ├── repository.go     # SQL queries (pgx)
│   │   ├── models.go         # Thread, Message, WS event structs
│   │   └── validation.go     # Content validation
│   ├── middleware/            # Auth middleware (JWT + blocked-user live check)
│   ├── upload/               # Multipart upload + static serving
│   └── server/server.go      # All routes wired here
├── migrations/               # 16 SQL pairs (.up.sql + .down.sql)
├── pkg/
│   ├── storage/              # File storage abstraction
│   └── notify/               # FCM push service + mock
├── tests/                    # Integration tests (real Postgres)
├── api_docs.md               # ⭐ Full API reference
├── test_guide.md
├── docker-compose.yml
└── Dockerfile
```

---

## Getting Started

### Run with Docker (Recommended)

```bash
# 1. Configure environment
# Create .env (see Environment Variables section below)

# 2. Start full stack
docker compose up --build -d

# 3. Verify
curl http://localhost:8080/health   # → OK
```

### Run Locally

```bash
# Start PostgreSQL only
docker compose up -d postgres

# Run the Go server (migrations auto-run on startup)
export JWT_SECRET=dev-secret ADMIN_SECRET=dev-admin
go run ./cmd/server
```

---

## Environment Variables

Create `.env` in the `backend/` directory:

```env
DB_HOST=localhost
DB_PORT=5433
DB_USER=college_hop
DB_PASSWORD=college_hop
DB_NAME=college_hop

JWT_SECRET=your-strong-secret-here
ADMIN_SECRET=your-admin-secret-here

UPLOAD_DIR=./uploads
UPLOAD_BASE_URL=http://localhost:8080/uploads
ALLOWED_ORIGIN=*
```

| Variable | Required | Description |
|---|---|---|
| `JWT_SECRET` | ✅ | Signs access tokens (HS256) |
| `ADMIN_SECRET` | ✅ | Header value for admin endpoints |
| `DB_*` | ✅ | PostgreSQL connection |
| `UPLOAD_DIR` | — | Local file storage (default: `./uploads`) |
| `UPLOAD_BASE_URL` | — | Public URL prefix for file links |
| `ALLOWED_ORIGIN` | — | CORS origin (default: `http://localhost:3000`) |

> ⚠️ `.env` is gitignored. Never commit it.

---

## Database & Migrations

Migrations run **automatically on every server start**. Never alter the database manually — always create a new migration pair.

| # | Migration | Effect |
|---|---|---|
| 001 | `create_otp_verifications` | OTP storage |
| 002 | `create_users` | Core users table |
| 003 | `create_profiles` | Profile data |
| 004 | `create_interests` | `interests`, `user_interests` |
| 005 | `add_attempts_to_otp` | Attempt counter |
| 006 | `create_refresh_tokens` | Token rotation |
| 007 | `add_user_status` | `pending`/`verified`/`blocked` |
| 008 | `create_events_groups` | `events`, `user_events`, `travel_groups`, `group_members` |
| 009 | `enhance_events` | Extra event fields |
| 010 | `add_alternate_email_and_connections` | `connections`, `user_preferences` |
| 011 | `add_travel_details_to_groups` | Group travel fields |
| 012 | `add_id_card_uploaded_at` | Upload timestamp |
| 013 | `create_messaging` | `message_threads`, `thread_participants`, `messages`, `device_tokens` |
| 014 | `add_last_read_at` | Unread count support |
| 015 | `add_chat_features` | `reply_to_id`, `is_forwarded` |
| 016 | `add_message_requests` | Connection request threads, 10-message DB limit |

```bash
# Create a new migration
migrate create -ext sql -dir migrations -seq your_description
```

---

## API Overview

Full documentation: **[api_docs.md](./api_docs.md)**

**46 endpoints total** across these modules:

| Module | Key Endpoints |
|---|---|
| Auth | `POST /auth/signup`, `/login`, `/verify`, `/refresh`, `/logout` |
| Profile | `GET/PUT /me`, `/me/preferences`, `/me/connections`, alternate email OTP |
| Upload | `POST /upload`, `GET /uploads/profile_photo/{f}`, `GET /uploads/id_card/{f}` |
| Events | `GET/POST /events`, `GET/PUT /me/event`, `GET /me/events` |
| Groups | `GET/POST /groups`, `GET/PUT/DELETE /groups/{id}`, join/leave/kick/suggested |
| Matching | `GET /users/matches?event_id=` |
| Profiles | `GET /users/{id}`, `POST /users/{id}/connect` |
| Admin | Users: pending/verify/block — Events: pending/approve/reject |
| Messaging | Threads, send, delete, read, clear, accept/decline, direct thread |
| Push | `POST /me/device-token` |
| WebSocket | `GET /ws?token=<JWT>` |

### Auth Flow

All protected routes require `Authorization: Bearer <access_token>`. The middleware performs a **live database blocked-user check on every request**.

```
POST /auth/signup {email}          → OTP sent (SHA-256 hashed, 5 min TTL)
POST /auth/verify {email, otp}     → {access_token, refresh_token}
POST /auth/refresh {refresh_token} → new token pair (old rotated out)
```

---

## WebSocket Protocol

**Connect:** `ws://localhost:8080/ws?token=<JWT>`

**Rate limit:** 30 messages/minute per connection.

### Client → Server

| Type | Payload |
|---|---|
| `message` | `{thread_id, content, reply_to_id?, is_forwarded?}` |
| `typing` | `{thread_id}` |

### Server → Client

| Type | Payload | Trigger |
|---|---|---|
| `new_message` | Full message object | Incoming message |
| `message_sent` | `{message_id, thread_id, created_at}` | Delivery confirmation |
| `message_deleted` | `{thread_id, message_id}` | Message unsent |
| `user_typing` | `{thread_id, user_id}` | Typing indicator |
| `presence_update` | `{user_id, is_online}` | Connect/disconnect |
| `error` | `{message}` | Server error |

---

## Architecture

### Request Flow

```
Request → Rate Limiter (20 req/s, burst 40, per IP)
        → Auth Middleware (JWT + live blocked-user check)
        → Handler (decode + validate)
        → Repository (pgx SQL)
        → PostgreSQL
```

### WebSocket Hub

The Hub is a **single long-running goroutine** owning a `map[userID]*Client`.

- Each `Client` has 2 goroutines: `readPump` + `writePump`.
- On **register**: broadcasts `presence_update {is_online: true}` to all contacts.
- On **unregister**: 500 ms buffer (device-swap), then broadcasts `presence_update {is_online: false}`.
- `hub.IsOnline(userID)` populates the `is_online` field in `GET /messages/threads` responses.
- `hub.BroadcastMessageDeleted(ctx, threadID, messageID)` is called by the REST delete handler.

### Design Decisions

| Decision | Rationale |
|---|---|
| No external HTTP framework | No dependency risk; stdlib `ServeMux` is sufficient |
| Repository interface pattern | Enables mock-based testing for every module |
| Single Hub goroutine | Serialises all state mutations — no lock contention |
| Hash-rotated refresh tokens | Prevents replay attacks |
| Live blocked-user check per request | Instantly enforces bans, no token wait |

---

## Testing

```bash
# PowerShell
$env:JWT_SECRET="test-secret"; go test ./tests/...

# Bash
JWT_SECRET="test-secret" go test ./tests/...

# All packages
go test ./...
```

Coverage includes: auth, profile, file upload, events, groups, peer matching, rate limiting, block enforcement, and repository SQL queries against real Postgres.

> When adding new repository methods, update the `Mock*Repository` in test files.

---

## Deployment

```bash
docker compose up --build -d

# Logs
docker logs collegehop-backend -f
docker logs collegehop-postgres -f
```

### Production Checklist

| Item | Action |
|---|---|
| `JWT_SECRET` | Strong random value (32+ chars) |
| `ADMIN_SECRET` | Rotate before go-live |
| `ALLOWED_ORIGIN` | Set to deployed frontend domain |
| `UPLOAD_BASE_URL` | Set to CDN/production URL |
| File storage | Migrate `./uploads` to S3/GCS |
| OTP delivery | Integrate Resend/SendGrid/SES (currently console-logged) |

---

## Known Issues & Tech Debt

| Issue | Severity |
|---|---|
| OTP not emailed — logged to console only | 🔴 High |
| Local file storage not durable across container restarts without volume mount | 🟡 Medium |
| Manual URL routing via `strings.Split` — consider `chi` router for v2 | 🟢 Low |
| No load testing on WebSocket Hub | 🟡 Medium |
