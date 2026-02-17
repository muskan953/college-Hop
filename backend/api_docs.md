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
