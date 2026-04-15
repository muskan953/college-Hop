# College Hop Backend API Documentation

## Base URL

```
http://localhost:8080
```

## Server Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `ALLOWED_ORIGIN` | `http://localhost:3000` | The single frontend origin allowed by CORS. Set to your deployed frontend URL in production. |
| `JWT_SECRET` | — | **Required.** Secret key for signing JWTs. |
| `ADMIN_SECRET` | — | **Required.** Shared secret for admin endpoints. |
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | — | PostgreSQL connection parameters. |
| `UPLOAD_DIR` | `./uploads` | Directory for uploaded files. |
| `UPLOAD_BASE_URL` | — | Public base URL for uploaded file links. |

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

> **Note on blocked accounts**: All protected endpoints (those requiring `Authorization: Bearer`) perform a **live database status check** on every request. If an admin has blocked your account, all protected endpoints will return `403 Forbidden` immediately, even if your access token has not expired yet.

---

### Rate Limiting

All endpoints are subject to a **per-IP rate limit** of **20 requests/second** with a burst of **40**. The server automatically determines the real client IP using the following priority order:

1. `X-Forwarded-For` header (set by reverse proxies like nginx / Render)
2. `X-Real-IP` header
3. TCP `RemoteAddr` (with port stripped)

When the limit is exceeded, the server responds with `429 Too Many Requests`.

---

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
| `200` | `{"message": "OTP sent"}` | OTP generated and delivered |
| `400` | `invalid email / personal email domains not allowed` | Email validation failed |
| `429` | `please wait before requesting another OTP` | Cooldown active (30 s between requests) |

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
| `200` | `{"message": "OTP sent"}` | OTP generated and delivered |
| `400` | `invalid email / personal email domains not allowed` | Email validation failed |
| `404` | `no account found with this email` | User does not exist |
| `429` | `please wait before requesting another OTP` | Cooldown active (30 s between requests) |

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
| `403` | Account has been blocked |
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
| `403` | Account has been blocked |

---

### `GET /me/preferences`

Returns the authenticated user's privacy and notification preferences.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
{
  "profile_visibility": "public",
  "show_location": false,
  "push_notifications": true,
  "email_notifications": true,
  "new_match_alerts": true,
  "message_alerts": true
}
```

| Status | Description |
|--------|-------------|
| `200` | Preferences returned |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |

---

### `PUT /me/preferences`

Updates the authenticated user's privacy and notification preferences.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "profile_visibility": "connections",
  "show_location": true,
  "push_notifications": true,
  "email_notifications": false,
  "new_match_alerts": true,
  "message_alerts": true
}
```

**Validation Rules**:

| Field | Constraint |
|-------|-----------|
| `profile_visibility` | Must be one of: `public`, `connections`, `private`. Defaults to `public` if empty |

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | `preferences updated` |
| `400` | Invalid `profile_visibility` value |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |

---

### `POST /me/alternate-email/request-otp`

Sends an OTP to the proposed alternate (personal) email to verify ownership.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "email": "user@gmail.com"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "OTP sent"}` | OTP generated and delivered |
| `400` | `invalid email address` | Email validation failed |
| `401` | — | Missing or invalid token |
| `403` | — | Account has been blocked |
| `429` | `please wait before requesting another OTP` | Cooldown active |

---

### `POST /me/alternate-email/verify`

Verifies the OTP and saves the alternate email to the user's profile.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "email": "user@gmail.com",
  "otp": "123456"
}
```

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "alternate email verified and saved"}` | Success |
| `400` | `email and otp are required` | Missing fields |
| `401` | `invalid or expired OTP` | OTP verification failed |
| `403` | — | Account has been blocked |

---

### `GET /me/connections`

Returns all confirmed connections for the authenticated user.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
[
  {
    "user_id": "uuid",
    "email": "alice@nitw.ac.in",
    "full_name": "Alice Kumar",
    "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg"
  }
]
```

| Status | Description |
|--------|-------------|
| `200` | List of connections (may be empty `[]`) |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |

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
| `403` | Account has been blocked |

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
| `403` | Account has been blocked |
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

### `GET /me/events`

Returns all events the authenticated user has selected (interested/going/looking_for_group).

**Auth**: `Authorization: Bearer <access_token>`

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
    "status": "approved",
    "user_status": "interested"
  }
]
```

**Notes**:
- Returns an empty array `[]` when the user hasn't selected any events.
- `user_status` is the user's relationship to the event (e.g. `interested`, `going`, `looking_for_group`).

| Status | Description |
|--------|-------------|
| `200` | List of user events (may be empty) |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |

---

### `GET /me/groups`

Returns all travel groups the authenticated user is currently a member of.

**Auth**: `Authorization: Bearer <access_token>`

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
    "created_at": "2026-03-01T00:00:00Z",
    "member_count": 3,
    "match_score": 0,
    "interests": null
  }
]
```

**Notes**:
- Returns an empty array `[]` when the user has not joined any groups.
- Groups are sorted by `created_at` descending (newest first).
- `match_score` and `interests` are `0`/`null` in this response (those are only populated by `GET /groups/suggested`).

| Status | Description |
|--------|-------------|
| `200` | List of groups (may be empty) |
| `401` | Missing or invalid token |

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

## Public Profiles & Connections

### `GET /users/{id}`

Returns a user's public profile. Requires authentication to prevent scraping.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
{
  "user_id": "uuid",
  "full_name": "Alice Kumar",
  "college_name": "NIT Warangal",
  "major": "CSE",
  "bio": "Loves hackathons",
  "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg",
  "interests": ["AI", "ML"],
  "is_alumni": false,
  "is_verified": true
}
```

| Status | Description |
|--------|-------------|
| `200` | Public profile returned |
| `400` | Missing user ID |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |
| `404` | User not found |

---

### `POST /users/{id}/connect`

Creates a connection between the authenticated user and the target user.

**Auth**: `Authorization: Bearer <access_token>`

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `201` | `{"message": "connected"}` | Connection created |
| `400` | `cannot connect with yourself` / `missing user id` | Invalid request |
| `401` | — | Missing or invalid token |
| `403` | — | Account has been blocked |
| `500` | `failed to create connection` | Server error |

**Notes**:
- Duplicate connections are silently ignored (upsert behavior).

---

## Travel Groups

### `GET /groups`

Lists all travel groups with an `is_joined` flag for the requesting user.

**Auth**: `Authorization: Bearer <access_token>`

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
    "created_at": "2026-03-01T00:00:00Z",
    "member_count": 3,
    "match_score": 0,
    "interests": null
  }
]
```

| Status | Description |
|--------|-------------|
| `200` | List of all groups |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |

---

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
| `403` | Account has been blocked |

---

### `POST /groups/{id}/join`

Joins an existing travel group.

**Auth**: `Authorization: Bearer <access_token>`

**Responses**:

| Status | Description |
|--------|-------------|
| `200` | `{"message": "joined group"}` |
| `400` | Group is full (capacity enforced atomically — no race condition) |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |
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

### `GET /groups/{id}`

Returns full details about a travel group including its member profiles.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
{
  "id": "uuid",
  "event_id": "uuid",
  "name": "Team Alpha",
  "description": "Looking for travel buddies",
  "created_by": "uuid",
  "max_members": 4,
  "created_at": "2026-03-01T00:00:00Z",
  "member_count": 2,
  "members": [
    {
      "user_id": "uuid",
      "full_name": "Muskan Sharma",
      "college_name": "NIT Warangal",
      "profile_photo_url": "http://localhost:8080/uploads/profile_photo/abc.jpg",
      "joined_at": "2026-03-01T00:00:00Z"
    }
  ]
}
```

| Status | Description |
|--------|-------------|
| `200` | Group details returned |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |
| `404` | Group not found |

---

### `PUT /groups/{id}`

Updates a group's name and/or description. **Creator only.**

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "name": "Team Alpha Updated",
  "description": "New travel plan description"
}
```

| Status | Description |
|--------|-------------|
| `200` | `{"message": "group updated"}` |
| `400` | Missing `name` |
| `401` | Missing or invalid token |
| `403` | Not the group creator, or account has been blocked |
| `404` | Group not found |

---

### `DELETE /groups/{id}`

Permanently deletes a group and removes all members. **Creator only.**

**Auth**: `Authorization: Bearer <access_token>`

| Status | Description |
|--------|-------------|
| `200` | `{"message": "group deleted"}` |
| `401` | Missing or invalid token |
| `403` | Not the group creator, or account has been blocked |
| `404` | Group not found |

---

### `POST /groups/{id}/leave`

Leave a travel group. **Not available to the group creator** (delete the group instead).

**Auth**: `Authorization: Bearer <access_token>`

| Status | Description |
|--------|-------------|
| `200` | `{"message": "left group"}` |
| `400` | Creator trying to leave, or user not a member |
| `401` | Missing or invalid token |
| `403` | Account has been blocked |
| `404` | Group not found |

---

### `POST /groups/{id}/kick`

Remove a member from the group. **Creator only.**

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "user_id": "uuid-of-member-to-kick"
}
```

| Status | Description |
|--------|-------------|
| `200` | `{"message": "member removed"}` |
| `400` | Missing `user_id`, user not a member, or creator kicking themselves |
| `401` | Missing or invalid token |
| `403` | Not the group creator, or account has been blocked |
| `404` | Group not found |

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

---

## Messaging

### `GET /messages/threads`

Lists all messaging threads for the authenticated user with unread counts and online status.

**Auth**: `Authorization: Bearer <access_token>`

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "name": "Alice Kumar",
    "other_user_id": "uuid",
    "last_message": "Hey!",
    "unread_count": 3,
    "is_online": true,
    "avatar_url": "http://localhost:8080/uploads/profile_photo/abc.jpg"
  }
]
```

---

### `GET /messages/{threadId}`

Returns paginated message history for a thread. Messages include reply and forward metadata.

**Auth**: `Authorization: Bearer <access_token>`

**Query Parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `before` | ISO 8601 datetime | Return messages before this time (pagination cursor) |

**Response** `200 OK`:
```json
[
  {
    "id": "uuid",
    "thread_id": "uuid",
    "sender_id": "uuid",
    "sender_name": "Alice Kumar",
    "content": "Hello!",
    "created_at": "2026-04-14T12:00:00Z",
    "reply_to_id": "uuid-or-null",
    "reply_to_content": "Original message text",
    "reply_to_sender": "Bob",
    "is_forwarded": false
  }
]
```

**Notes**:
- `reply_to_content` and `reply_to_sender` are populated via `LEFT JOIN` when `reply_to_id` is set
- `is_forwarded` is `true` when message was forwarded from another thread
- Returns 50 messages per page, newest first

---

### `POST /messages/send`

Sends a message via HTTP (fallback when WebSocket is unavailable).

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "thread_id": "uuid",
  "content": "Hello!",
  "reply_to_id": "uuid-or-null",
  "is_forwarded": false
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `thread_id` | Yes | Target thread |
| `content` | Yes | Message text (max 8192 chars) |
| `reply_to_id` | No | UUID of message being replied to |
| `is_forwarded` | No | `true` if message is being forwarded |

**Response** `201 Created`:
```json
{
  "message_id": "uuid"
}
```

---

### `POST /messages/thread/direct`

Gets or creates a 1:1 direct message thread with another user.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "user_id": "uuid"
}
```

---

### `DELETE /messages/{messageId}`

Deletes a message for all participants ("Unsend for Everyone"). Only the sender can delete.

**Auth**: `Authorization: Bearer <access_token>`

| Status | Description |
|--------|-------------|
| `204` | Message deleted |
| `404` | Message not found or not yours |

---

### `POST /messages/threads/{id}/read`

Marks all messages in a thread as read.

**Auth**: `Authorization: Bearer <access_token>`

---

### `POST /messages/threads/{id}/clear`

Clears chat history for the authenticated user only (sets `cleared_at`).

**Auth**: `Authorization: Bearer <access_token>`

---

## Push Notifications

### `POST /me/device-token`

Registers a device token (FCM) for push notifications.

**Auth**: `Authorization: Bearer <access_token>`

**Request Body**:
```json
{
  "token": "fcm-device-token-string",
  "platform": "android"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `token` | Yes | FCM device token |
| `platform` | No | Device platform. Defaults to `android` if not provided |

**Responses**:

| Status | Body | Description |
|--------|------|-------------|
| `200` | `{"message": "token registered"}` | Token saved/updated |
| `400` | `token is required` | Missing token field |
| `401` | — | Missing or invalid token |
| `403` | — | Account has been blocked |

---

## WebSocket

### `GET /ws?token=<JWT>`

Upgrades to a WebSocket connection for real-time messaging.

### Client → Server Messages

| Type | Payload | Description |
|------|---------|-------------|
| `message` | `{thread_id, content, reply_to_id?, is_forwarded?}` | Send a message with optional reply/forward metadata |
| `typing` | `{thread_id}` | Notify that user is typing |

### Server → Client Messages

| Type | Payload | Description |
|------|---------|-------------|
| `new_message` | Full message object (includes `reply_to_content`, `reply_to_sender`, `is_forwarded`) | New incoming message |
| `message_sent` | `{message_id, thread_id, created_at}` | Confirmation with real message ID |
| `message_deleted` | `{thread_id, message_id}` | Real-time deletion broadcast |
| `user_typing` | `{thread_id, user_id}` | Typing indicator |
| `presence_update` | `{user_id, is_online}` | Online/offline status change |
| `error` | `{message}` | Error feedback |
