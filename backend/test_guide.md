# Comprehensive Testing Guide

This guide explains how to test the College Hop backend both automatically (using the new test suite) and manually (via `curl`).

## 1. Automated Integration Tests (Recommended)

We have implemented a consolidated integration test suite located in the `tests/` directory. These tests cover:
- **Authentication**: Signup, Email Validation, OTP Verification.
- **Profile**: Create, Get, and Update profiles.
- **Upload**: File uploads for profile photos.
- **Events**: List events, create events (auth + validation), set user event.
- **Groups**: Create groups (auth + validation), join groups (capacity check), suggested groups.
- **Matching**: Peer matching (scored, sorted, filtered results), Jaccard similarity algorithm.
- **Database Repository**: Verifies real SQL queries against a running Postgres database.

### Prerequisites
- **Docker**: Must be running (`docker compose up -d`) because the repository tests connect to the real database.
- **Go**: Installed on your machine.

### Running the Tests
Run the following command in the `backend` directory:

```powershell
# Windows (PowerShell)
$env:JWT_SECRET="test-secret"; go test ./tests/...

# Linux/Mac (Bash)
JWT_SECRET="test-secret" go test ./tests/...
```

*Note: The tests automatically connect to the database on port `5433` (as configured in test helpers) to avoid conflicts with other local databases.*

---

## 2. Manual Testing Setup

### Prerequisites
Ensure the server is running using Docker:
```bash
docker compose up -d --build
```

### Health Check
Verify the server is up and reachable.
```bash
curl -i http://localhost:8080/health
```

### Authentication Flow

#### Step A: Signup
Send a request to receive an OTP.
```bash
curl -i -X POST http://localhost:8080/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@nitw.ac.in"}'
```
*Note: Check the backend logs (`docker logs collegehop-backend`) to see the printed OTP for testing purposes.*

#### Step B: Verify OTP
Exchange the OTP for a JWT token. Replace `<OTP>` with the one from the logs.
```bash
curl -i -X POST http://localhost:8080/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"email": "test@nitw.ac.in", "otp": "<OTP>"}'
```
*Output: You will receive a `token` in the JSON response.*

### Protected Routes
Use the token received in the previous step as a Bearer token.

#### Get My Profile
```bash
curl -i -X GET http://localhost:8080/me \
  -H "Authorization: Bearer <TOKEN>"
```

#### Update My Profile
```bash
curl -i -X PUT http://localhost:8080/me \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "college_name": "NIT Warangal",
    "major": "Computer Science",
    "roll_number": "123456",
    "profile_photo_url": "http://localhost:8080/uploads/profile.jpg",
    "college_id_card_url": "http://localhost:8080/uploads/id.pdf"
  }'
```

#### Upload a File
Test the upload endpoint (e.g., uploading an image).
```bash
# Ensure you have a 'test.jpg' file in the current directory
curl -i -X POST http://localhost:8080/upload \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@test.jpg"
```

### Events

#### List Approved Events (public)
```bash
curl -i http://localhost:8080/events
```

#### Submit a New Event (requires auth)
```bash
curl -i -X POST http://localhost:8080/events \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "TechFest 2026",
    "date": "2026-03-15",
    "location": "NIT Warangal",
    "organizer": "CSE Dept",
    "url": "https://techfest.nitw.ac.in"
  }'
```

#### Approve an Event (admin)
```bash
curl -i -X POST http://localhost:8080/admin/events/<EVENT_ID>/approve \
  -H "X-Admin-Secret: <ADMIN_SECRET>"
```

#### Select an Event
```bash
curl -i -X PUT http://localhost:8080/me/event \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"event_id": "<EVENT_ID>", "status": "interested"}'
```

### Travel Groups

#### Create a Group
```bash
curl -i -X POST http://localhost:8080/groups \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "event_id": "<EVENT_ID>",
    "name": "Team Alpha",
    "description": "Looking for travel buddies",
    "max_members": 4
  }'
```

#### Join a Group
```bash
curl -i -X POST http://localhost:8080/groups/<GROUP_ID>/join \
  -H "Authorization: Bearer <TOKEN>"
```

#### Get Suggested Groups
```bash
curl -i http://localhost:8080/groups/suggested?event_id=<EVENT_ID> \
  -H "Authorization: Bearer <TOKEN>"
```

### Peer Matching

#### Find Best Matches
```bash
curl -i http://localhost:8080/users/matches?event_id=<EVENT_ID> \
  -H "Authorization: Bearer <TOKEN>"
```
