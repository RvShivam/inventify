# Inventify API Guide

## Base URL
```
http://localhost:8080
```

## Authentication
Protected endpoints require a valid JWT access token in the `Authorization` header:
```
Authorization: Bearer <access_token>
```

---

## Auth Endpoints

### POST `/api/auth/signup`
Register a new user. Optionally create an organization (shop) or join one via referral code.

**Rate Limit:** 5 requests/minute per IP

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "mypassword123",
  "shop_name": "John's Electronics",
  "referral_code": ""
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | Yes | |
| `email` | string | Yes | Must be valid email, unique |
| `password` | string | Yes | Min 8 characters |
| `shop_name` | string | No | Creates a new org as owner |
| `referral_code` | string | No | Joins existing org as staff |

**Success Response (201):**
```json
{
  "message": "Account created successfully",
  "user_id": 1,
  "access_token": "eyJhbGci..."
}
```
Also sets `refresh_token` as an HTTP-only cookie.

**Error Responses:**
| Status | Cause |
|--------|-------|
| 400 | Missing/invalid fields, short password, invalid referral |
| 409 | Email already in use |
| 429 | Rate limit exceeded |

---

### POST `/api/auth/login`
Authenticate and receive tokens.

**Rate Limit:** 10 requests/minute per IP

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "mypassword123"
}
```

**Success Response (200):**
```json
{
  "access_token": "eyJhbGci...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "org_id": 1,
    "role": "owner"
  }
}
```
Also sets `refresh_token` as an HTTP-only cookie.

**Error Responses:**
| Status | Cause |
|--------|-------|
| 400 | Missing fields |
| 401 | Wrong email or password |
| 429 | Rate limit exceeded |

---

### POST `/api/auth/refresh`
Exchange a valid refresh token for a new access + refresh token pair (token rotation).

**Rate Limit:** 10 requests/minute per IP

**Authentication:** Refresh token sent automatically via HTTP-only cookie (no manual header needed).

**Success Response (200):**
```json
{
  "access_token": "eyJhbGci..."
}
```
Also sets a new `refresh_token` cookie (the old one is revoked).

**Error Responses:**
| Status | Cause |
|--------|-------|
| 401 | Missing, invalid, expired, or revoked refresh token |
| 429 | Rate limit exceeded |

---

### POST `/api/auth/logout`
Revoke the current refresh token and clear the cookie.

**Authentication:** Requires `Authorization: Bearer <access_token>` header.

**Success Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

### GET `/api/me`
Get the authenticated user's profile.

**Authentication:** Required.

**Success Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "org_id": 1,
  "role": "owner"
}
```

**Error Responses:**
| Status | Cause |
|--------|-------|
| 401 | Missing or invalid token |
| 404 | User not found |

---

## Token Strategy

| Token | Lifetime | Delivery |
|-------|----------|----------|
| Access Token | 15 minutes | Response body, sent via `Authorization` header |
| Refresh Token | 7 days | HTTP-only cookie, auto-sent by browser |

**Flow:**
1. Login/Signup → receive access token in body + refresh token in cookie
2. Use access token for API calls
3. When access token expires → call `/api/auth/refresh` → receive new pair
4. Logout → refresh token revoked, cookie cleared
