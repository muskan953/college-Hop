# College Hop Backend API Documentation

## Base URL

```
http://localhost:8080
```

---

## Health Check

### `GET /health`

Returns the server status.

**Auth**: None

**Response** `200 OK`:
```
OK
```

---

## Authentication

### `POST /auth/signup`

Sends an OTP to the given email address.

**Auth**: None

**Request Body**:
```json
{
  "email": "student@nitw.ac.in"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "OTP sent"}` | OTP generated and logged |
| `400` | `invalid email / personal email domains not allowed` | Email validation failed |
| `429` | `please wait before requesting another OTP` | Rate limited (1 OTP per minute) |

---

### `POST /auth/login`

Sends an OTP to the given email address, but only if the user already exists.

**Auth**: None

**Request Body**:
```json
{
  "email": "student@nitw.ac.in"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "OTP sent"}` | OTP generated and logged |
| `400` | `invalid email / personal email domains not allowed` | Email validation failed |
| `404` | `no account found with this email` | User does not exist |
| `429` | `please wait before requesting another OTP` | Rate limited (1 OTP per minute) |

---

### `POST /auth/verify`

Verifies the OTP and returns JWT tokens.

**Auth**: None

**Request Body**:
```json
{
  "email": "student@nitw.ac.in",
  "otp": "123456"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"access_token": "...", "refresh_token": "..."}` | Login successful |
| `401` | `invalid or expired otp` | Wrong OTP or expired |
| `423` | `too many failed attempts, request a new OTP` | 5 failed attempts |

---

### `POST /auth/refresh`

Rotates the refresh token and issues a new token pair.

**Auth**: None (uses refresh token in body)

**Request Body**:
```json
{
  "refresh_token": "your-refresh-token"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"access_token": "...", "refresh_token": "..."}` | New token pair |
| `401` | `invalid refresh token / revoked / expired` | Token invalid |

---

### `POST /auth/logout`

Revokes the refresh token (ends the session).

**Auth**: None (uses refresh token in body)

**Request Body**:
```json
{
  "refresh_token": "your-refresh-token"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "logged out successfully"}` | Session ended |

---

## Profile

### `GET /me`

Returns the authenticated user's profile including verification status.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
{
  "full_name": "Muskan Sharma",
  "college_name": "NIT Warangal",
  "major": "CSE",
  "roll_number": "21CS1001",
  "id_expiration": "2026-06-01",
  "bio": "Loves hackathons",
  "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg",
  "college_id_card_url": "http://localhost:8080/uploads/id_card/xyz.pdf",
  "interests": ["Coding", "Music"],
  "status": "pending"
}
```

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | Profile returned |
| `401` | Missing or invalid token |
| `404` | Profile not found |

---

### `PUT /me`

Creates or updates the authenticated user's profile.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "full_name": "Muskan Sharma",
  "college_name": "NIT Warangal",
  "major": "CSE",
  "roll_number": "21CS1001",
  "id_expiration": "2026-06-01",
  "bio": "Loves hackathons",
  "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg",
  "college_id_card_url": "http://localhost:8080/uploads/id_card/xyz.pdf",
  "interests": ["Coding", "Music"]
}
```

**Validation Rules**:

| Field | Constraint |
|-------|-----------|
| `full_name` | Required, max 50 chars |
| `college_name` | Required, max 100 chars |
| `major` | Required, max 50 chars |
| `roll_number` | Required, max 20 chars |
| `bio` | Optional, max 500 chars |
| `profile_photo_url` | Must be valid URL ending in `.jpg`, `.png`, or `.webp` |
| `college_id_card_url` | Must be valid URL ending in `.pdf` |

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | `profile updated` |
| `400` | Validation error (details in body) |
| `401` | Missing or invalid token |

---

## File Upload

### `POST /upload`

Uploads a file (profile photo or ID card).

**Auth**: `Authorization: Bearer <access_token>`

**Request**: `multipart/form-data`

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | `profile_photo` or `id_card` |
| `file` | file | The file to upload |

**File Constraints**:

| Type | Allowed MIME | Max Size |
|------|-------------|----------|
| `profile_photo` | `image/jpeg`, `image/png`, `image/webp` | 5 MB |
| `id_card` | `application/pdf` | 5 MB |

**Response** `200 OK`:
```json
{
  "url": "http://localhost:8080/uploads/profile_photo/uuid.jpg"
}
```

---

### `GET /uploads/profile_photo/{filename}`

Serves a profile photo. **Public** — no auth required.

---

### `GET /uploads/id_card/{filename}`

Serves an ID card PDF. **Auth required** — Bearer token needed.

---

## Admin

All admin endpoints require the `X-Admin-Secret` header matching the `ADMIN_SECRET` environment variable.

### `GET /admin/users/pending`

Lists all users with `status = 'pending'`.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`:
```json
[
  {
    "user_id": "uuid",
    "email": "student@nitw.ac.in",
    "status": "pending",
    "full_name": "Muskan Sharma",
    "college_name": "NIT Warangal",
    "college_id_card_url": "http://localhost:8080/uploads/id_card/xyz.pdf"
  }
]
```

---

### `POST /admin/users/{id}/verify`

Sets a user's status to `verified`.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`:
```json
{
  "message": "user verified",
  "user_id": "uuid"
}
```

---

### `POST /admin/users/{id}/block`

Sets a user's status to `blocked`.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`:
```json
{
  "message": "user blocked",
  "user_id": "uuid"
}
```

**Error Responses** (all admin endpoints):

| Status | Description |
|--------|-------------|
| `403` | Missing or wrong `X-Admin-Secret` |
| `404` | User not found |
| `503` | `ADMIN_SECRET` not configured |

---

## Events

### `GET /events`

Lists all approved events.

**Auth**: None

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "name": "TechFest 2026",
    "category": "Technical Fest",
    "venue": "NIT Warangal",
    "organizer": "CSE Dept",
    "start_date": "2026-03-15T00:00:00Z",
    "end_date": "2026-03-17T00:00:00Z",
    "time_description": "9 AM - 6 PM",
    "event_link": "https://techfest.nitw.ac.in",
    "brochure_url": "https://techfest.nitw.ac.in/brochure.pdf",
    "ticket_link": "https://techfest.nitw.ac.in/tickets",
    "status": "approved",
    "created_at": "2026-02-18T00:00:00Z"
  }
]
```

---

### `POST /events`

Submits a new event for admin approval.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "name": "TechFest 2026",
  "category": "Technical Fest",
  "venue": "NIT Warangal",
  "organizer": "CSE Dept",
  "start_date": "2026-03-15",
  "end_date": "2026-03-17",
  "time_description": "9 AM - 6 PM",
  "event_link": "https://techfest.nitw.ac.in",
  "brochure_url": "https://techfest.nitw.ac.in/brochure.pdf",
  "ticket_link": "https://techfest.nitw.ac.in/tickets"
}
```

**Validation Rules**:

| Field | Constraint |
|-------|------------|
| `name` | Required |
| `venue` | Required |
| `organizer` | Required |
| `start_date` | Required, format `YYYY-MM-DD` |
| `end_date` | Optional, format `YYYY-MM-DD`, must be ≥ `start_date` |
| `category` | Optional |
| `time_description` | Optional (e.g. `"9 AM - 6 PM"`) |
| `event_link` | Optional, official event page URL |
| `brochure_url` | Optional, URL to official brochure |
| `ticket_link` | Optional, URL to ticket purchase page |

**Responses**:

| Status | Description |
|--------|-------------|
| `201` | Event created with `status: "pending"` |
| `400` | Missing required fields or invalid date format |
| `401` | Missing or invalid token |

---

### `PUT /me/event`

Sets the user's currently selected event.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "event_id": "uuid",
  "status": "interested"
}
```

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | `{"message": "event set"}` |
| `400` | Missing `event_id` or event not approved |
| `401` | Missing or invalid token |
| `404` | Event not found |

---

### `GET /me/event`

Returns the user's currently selected event.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
{
  "event": {
    "id": "uuid",
    "name": "TechFest 2026",
    "category": "Technical Fest",
    "venue": "NIT Warangal",
    "organizer": "CSE Dept",
    "start_date": "2026-03-15T00:00:00Z",
    "end_date": "2026-03-17T00:00:00Z",
    "event_link": "https://techfest.nitw.ac.in",
    "status": "approved"
  },
  "status": "interested"
}
```

---

### `GET /admin/events/pending`

Lists all events pending approval.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`: Array of events with `status: "pending"`.

---

### `POST /admin/events/{id}/approve`

Approves a pending event.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`:
```json
{"message": "event approved"}
```

---

### `POST /admin/events/{id}/reject`

Rejects a pending event.

**Auth**: `X-Admin-Secret: <secret>`

**Response** `200 OK`:
```json
{"message": "event rejected"}
```

---

## Travel Groups

### `POST /groups`

Creates a new travel group for an event. The creator is automatically added as the first member.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "event_id": "uuid",
  "name": "Team Alpha",
  "description": "Looking for travel buddies from Hyderabad",
  "max_members": 4
}
```

**Notes**:
- `max_members` defaults to 4, maximum 6
- Creator is auto-joined as the first member

**Responses**:

| Status | Description |
|--------|-------------|
| `201` | Group created |
| `400` | Missing `name` or `event_id` |
| `401` | Missing or invalid token |

---

### `POST /groups/{id}/join`

Joins an existing travel group.

**Auth**: `Authorization: Bearer <access_token>`

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | `{"message": "joined group"}` |
| `400` | Group is full |
| `401` | Missing or invalid token |
| `404` | Group not found |

---

### `GET /groups/suggested?event_id=<uuid>`

Returns groups for an event, scored and sorted by interest similarity with the user.

**Auth**: `Authorization: Bearer <access_token>`

**Algorithm**: Log-Enhanced Jaccard Similarity with strict filtering.

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "event_id": "uuid",
    "name": "Team Alpha",
    "description": "Looking for travel buddies",
    "created_by": "uuid",
    "max_members": 4,
    "member_count": 2,
    "match_score": 0.556,
    "interests": ["AI", "ML", "Robotics"]
  }
]
```

**Notes**:
- Full groups are excluded
- Groups where any member has zero interest overlap are filtered out
- Results sorted by `match_score` descending

---

## Peer Matching

### `GET /users/matches?event_id=<uuid>`

Finds the best peer matches for the user at a specific event.

**Auth**: `Authorization: Bearer <access_token>`

**Algorithm**: `Score = (|Intersection| / |Union|) × log₁₀(1 + |Intersection|)`

**Response** `200 OK`:
```json
[
  {
    "user_id": "uuid",
    "full_name": "Alice Kumar",
    "college_name": "NIT Warangal",
    "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg",
    "common_interests": ["AI", "ML"],
    "match_score": 0.556
  }
]
```

**Notes**:
- Returns top 10 matches
- Users with zero interest overlap are filtered out
- Results sorted by `match_score` descending
