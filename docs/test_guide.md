# Inventify Test Guide

## Prerequisites
1. **Docker Desktop** must be running
2. **PostgreSQL** container must be up via `docker-compose`
3. A test database `inventify_test` must exist

## Setup

### 1. Start Infrastructure
```bash
docker-compose up -d
```

### 2. Create Test Database
```bash
docker exec inventify_db psql -U postgres -c "CREATE DATABASE inventify_test;"
```

### 3. Run All Tests
```bash
cd server
go test ./tests/ -v
```

---

## Test Suite Coverage

### Signup Tests (6 tests)
| Test | What it verifies |
|------|-----------------|
| `TestSignup_ValidOwner` | Valid signup creates user, org, returns access token + refresh cookie |
| `TestSignup_ValidWithReferral` | Signup with valid referral code joins existing org |
| `TestSignup_DuplicateEmail` | Duplicate email returns `409 Conflict` |
| `TestSignup_MissingFields` | Missing name/email/password returns `400` |
| `TestSignup_PasswordTooShort` | Password < 8 chars returns `400` |
| `TestSignup_InvalidEmail` | Malformed email returns `400` |
| `TestSignup_InvalidReferral` | Non-existent referral code returns `400` |

### Login Tests (4 tests)
| Test | What it verifies |
|------|-----------------|
| `TestLogin_Valid` | Correct credentials return access token + profile + refresh cookie |
| `TestLogin_WrongPassword` | Wrong password returns `401` |
| `TestLogin_NonExistentUser` | Non-existent email returns `401` |
| `TestLogin_MissingFields` | Missing email/password returns `400` |

### Refresh Token Tests (4 tests)
| Test | What it verifies |
|------|-----------------|
| `TestRefresh_Valid` | Valid refresh returns new access token + rotated refresh cookie |
| `TestRefresh_InvalidToken` | Fake token ID returns `401` |
| `TestRefresh_NoCookie` | Missing cookie returns `401` |
| `TestRefresh_RevokedToken` | Reusing a rotated (revoked) token returns `401` |

### Logout Tests (1 test)
| Test | What it verifies |
|------|-----------------|
| `TestLogout_Valid` | Logout revokes token; subsequent refresh attempt returns `401` |

### Profile Tests (4 tests)
| Test | What it verifies |
|------|-----------------|
| `TestProfile_Valid` | Returns correct name, email, role for authenticated user |
| `TestProfile_NoToken` | No Authorization header returns `401` |
| `TestProfile_InvalidToken` | Invalid JWT returns `401` |
| `TestProfile_MalformedHeader` | Non-Bearer format returns `401` |

### Rate Limiting Tests (2 tests)
| Test | What it verifies |
|------|-----------------|
| `TestRateLimit_Signup` | 6th request within a minute returns `429 Too Many Requests` |
| `TestRateLimit_Login` | 11th request within a minute returns `429 Too Many Requests` |

---

## Manual Testing with curl

### Signup
```bash
curl -X POST http://localhost:8080/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"password123","shop_name":"Test Shop"}' \
  -c cookies.txt
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  -c cookies.txt
```

### Get Profile (use access_token from login response)
```bash
curl http://localhost:8080/api/me \
  -H "Authorization: Bearer <access_token>"
```

### Refresh Token
```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -b cookies.txt -c cookies.txt
```

### Logout
```bash
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Authorization: Bearer <access_token>" \
  -b cookies.txt
```
