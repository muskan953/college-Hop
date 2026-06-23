# 🎓 College Hop

> **Connect. Discover. Travel Together.**

College Hop is a cross-platform mobile app that helps verified college students discover inter-college events, form interest-matched travel groups, find peer matches, and connect via real-time messaging — all within a trust-first, institutionally verified network.

---

## 📱 What It Does

| Feature | Description |
|---|---|
| **Event Discovery** | Browse hackathons, fests, and conferences across colleges |
| **Travel Groups** | Form or join travel groups for events with interest-matched peers |
| **Peer Matching** | Find other attendees using a log-enhanced Jaccard similarity algorithm |
| **Real-Time Messaging** | 1:1 chat with WebSocket-powered presence, typing indicators, and push notifications |
| **Trust & Verification** | Institutional email + college ID card verification with admin approval |

---

## 🗂️ Repository Structure

This is a **monorepo** containing the backend and frontend as sibling directories:

```
college-Hop/
├── backend/                  # Go REST API + WebSocket server
│   ├── cmd/                  # main.go entrypoint
│   ├── internal/             # Business logic modules (auth, profile, events, groups, messages, admin)
│   ├── migrations/           # 16 PostgreSQL migration pairs (up/down)
│   ├── pkg/                  # Shared packages (storage, notify)
│   ├── tests/                # Integration test suite
│   ├── docker-compose.yml    # Full stack: Go + PostgreSQL
│   ├── Dockerfile
│   └── api_docs.md           # Full API reference
│
└── college_hop_frontend/     # Flutter mobile + web app
    └── lib/
        ├── providers/        # State management (5 providers)
        ├── services/         # API + WebSocket clients
        ├── screen/           # UI screens
        ├── models/
        ├── widgets/
        └── main.dart
```

---

## ⚡ Quick Start

### Option 1 — Full Docker Stack (Recommended)

```bash
cd backend
# Copy and configure environment variables
cp .env.example .env   # edit JWT_SECRET, ADMIN_SECRET, etc.

# Start everything (Go backend + PostgreSQL)
docker compose up --build -d
```

Backend available at `http://localhost:8080`. Health check: `GET /health → OK`.

Then run the Flutter app:

```bash
cd college_hop_frontend
flutter pub get
flutter run                       # connected device / emulator
# flutter run -d chrome           # web (WebSocket works on localhost)
```

### Option 2 — Local Development

```bash
# Terminal 1: Start PostgreSQL only
cd backend && docker compose up -d postgres

# Terminal 2: Run Go backend (hot-reload not included, re-run on changes)
cd backend && go run ./cmd/...

# Terminal 3: Run Flutter
cd college_hop_frontend && flutter run
```

---

## 🛠️ Tech Stack

### Backend
| Layer | Technology |
|---|---|
| Language | Go 1.25 |
| HTTP Router | `net/http` (stdlib) |
| Database | PostgreSQL 15 |
| DB Driver | `jackc/pgx/v5` |
| Migrations | `golang-migrate/v4` |
| Auth | JWT (`golang-jwt/v5`) |
| WebSockets | `gorilla/websocket` |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Rate Limiting | `golang.org/x/time/rate` |
| Container | Docker + Docker Compose |

### Frontend
| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.8.1) |
| State Management | `provider` ^6.1.2 |
| HTTP Client | `http` ^1.2.1 |
| WebSockets | `web_socket_channel` |
| Push Notifications | `firebase_messaging` |
| Secure Storage | `flutter_secure_storage` |

---

## 🔑 Environment Variables (Backend)

> ⚠️ Never commit `.env` — it is gitignored.

| Variable | Required | Description |
|---|---|---|
| `JWT_SECRET` | ✅ | Secret key for signing access tokens |
| `ADMIN_SECRET` | ✅ | Shared secret for admin endpoints |
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | ✅ | PostgreSQL connection |
| `UPLOAD_DIR` | — | Directory for uploaded files (default: `./uploads`) |
| `UPLOAD_BASE_URL` | — | Public URL prefix for file links |
| `ALLOWED_ORIGIN` | — | CORS allowed origin (default: `http://localhost:3000`) |

---

## 📊 Project Scale

| Metric | Value |
|---|---|
| Go codebase | ~9,000 lines |
| REST API endpoints | 46 |
| Database tables | 17 |
| Migrations | 16 |
| Flutter providers | 5 |
| WebSocket event types | 8 (2 client→server, 6 server→client) |

---

## 📂 Key Documents

| Document | Location |
|---|---|
| Full API Reference | [`backend/api_docs.md`](./backend/api_docs.md) |
| Testing Guide | [`backend/test_guide.md`](./backend/test_guide.md) |
| Knowledge Transfer | [`KT.md`](./KT.md) |
| Product Requirements | [`PRD.md`](./PRD.md) |
| Backend README | [`backend/README.md`](./backend/README.md) |
| Frontend README | [`college_hop_frontend/README.md`](./college_hop_frontend/README.md) |

---

## 🚀 Deployment

The backend is containerised and designed for deployment on any Docker-capable host (e.g., AWS EC2, Render, Railway).

```bash
cd backend
docker compose up --build -d
```

See [`backend/README.md`](./backend/README.md) for the full production checklist.

---

## 📄 License

Private repository — `muskan953/college-Hop`.
