package tests

import (
	"fmt"
	"net/http"
	"testing"
)

// ════════════════════════════════════════════════════════════
//  SIGNUP TESTS
// ════════════════════════════════════════════════════════════

func TestSignup_ValidOwner(t *testing.T) {
	env := SetupTestEnv(t)

	body := map[string]string{
		"name":      "Alice",
		"email":     "alice@example.com",
		"password":  "password123",
		"shop_name": "Alice's Shop",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201, got %d: %s", w.Code, w.Body.String())
	}

	result := ParseJSON(w)
	if result["access_token"] == nil || result["access_token"] == "" {
		t.Fatal("Expected access_token in response")
	}
	if result["user_id"] == nil {
		t.Fatal("Expected user_id in response")
	}

	// Verify refresh token cookie is set
	cookie := ExtractCookie(w, "refresh_token")
	if cookie == nil {
		t.Fatal("Expected refresh_token cookie to be set")
	}
	if !cookie.HttpOnly {
		t.Fatal("Expected refresh_token cookie to be HttpOnly")
	}
}

func TestSignup_ValidWithReferral(t *testing.T) {
	env := SetupTestEnv(t)

	// First create an owner
	owner := map[string]string{
		"name":      "Owner",
		"email":     "owner@example.com",
		"password":  "password123",
		"shop_name": "My Shop",
	}
	DoJSON(env.Router, "POST", "/api/auth/signup", owner)

	// Get the org's referral code from DB
	var org struct{ ReferralCode string }
	env.DB.Raw("SELECT referral_code FROM organizations LIMIT 1").Scan(&org)

	// Now signup with referral
	staff := map[string]string{
		"name":          "Staff",
		"email":         "staff@example.com",
		"password":      "password123",
		"referral_code": org.ReferralCode,
	}
	w := DoJSON(env.Router, "POST", "/api/auth/signup", staff)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201, got %d: %s", w.Code, w.Body.String())
	}
}

func TestSignup_DuplicateEmail(t *testing.T) {
	env := SetupTestEnv(t)

	body := map[string]string{
		"name":     "Test",
		"email":    "dup@example.com",
		"password": "password123",
	}
	DoJSON(env.Router, "POST", "/api/auth/signup", body)
	w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

	if w.Code != http.StatusConflict {
		t.Fatalf("Expected 409 for duplicate email, got %d: %s", w.Code, w.Body.String())
	}
}

func TestSignup_MissingFields(t *testing.T) {
	env := SetupTestEnv(t)

	tests := []struct {
		name string
		body map[string]string
	}{
		{"missing name", map[string]string{"email": "a@b.com", "password": "password123"}},
		{"missing email", map[string]string{"name": "Test", "password": "password123"}},
		{"missing password", map[string]string{"name": "Test", "email": "c@d.com"}},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			w := DoJSON(env.Router, "POST", "/api/auth/signup", tc.body)
			if w.Code != http.StatusBadRequest {
				t.Fatalf("Expected 400 for %s, got %d: %s", tc.name, w.Code, w.Body.String())
			}
		})
	}
}

func TestSignup_PasswordTooShort(t *testing.T) {
	env := SetupTestEnv(t)

	body := map[string]string{
		"name":     "Test",
		"email":    "short@example.com",
		"password": "123",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 for short password, got %d: %s", w.Code, w.Body.String())
	}
}

func TestSignup_InvalidEmail(t *testing.T) {
	env := SetupTestEnv(t)

	body := map[string]string{
		"name":     "Test",
		"email":    "not-an-email",
		"password": "password123",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 for invalid email, got %d: %s", w.Code, w.Body.String())
	}
}

func TestSignup_InvalidReferral(t *testing.T) {
	env := SetupTestEnv(t)

	body := map[string]string{
		"name":          "Test",
		"email":         "ref@example.com",
		"password":      "password123",
		"referral_code": "nonexistent-code",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 for invalid referral, got %d: %s", w.Code, w.Body.String())
	}
}

// ════════════════════════════════════════════════════════════
//  LOGIN TESTS
// ════════════════════════════════════════════════════════════

func TestLogin_Valid(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup first
	signup := map[string]string{
		"name":     "LoginUser",
		"email":    "login@example.com",
		"password": "password123",
	}
	DoJSON(env.Router, "POST", "/api/auth/signup", signup)

	// Login
	login := map[string]string{
		"email":    "login@example.com",
		"password": "password123",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/login", login)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200, got %d: %s", w.Code, w.Body.String())
	}

	result := ParseJSON(w)
	if result["access_token"] == nil {
		t.Fatal("Expected access_token")
	}
	if result["user"] == nil {
		t.Fatal("Expected user profile in response")
	}

	cookie := ExtractCookie(w, "refresh_token")
	if cookie == nil {
		t.Fatal("Expected refresh_token cookie")
	}
}

func TestLogin_WrongPassword(t *testing.T) {
	env := SetupTestEnv(t)

	signup := map[string]string{
		"name":     "WrongPw",
		"email":    "wrongpw@example.com",
		"password": "password123",
	}
	DoJSON(env.Router, "POST", "/api/auth/signup", signup)

	login := map[string]string{
		"email":    "wrongpw@example.com",
		"password": "wrongpassword",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/login", login)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestLogin_NonExistentUser(t *testing.T) {
	env := SetupTestEnv(t)

	login := map[string]string{
		"email":    "nobody@example.com",
		"password": "password123",
	}
	w := DoJSON(env.Router, "POST", "/api/auth/login", login)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestLogin_MissingFields(t *testing.T) {
	env := SetupTestEnv(t)

	tests := []struct {
		name string
		body map[string]string
	}{
		{"missing email", map[string]string{"password": "password123"}},
		{"missing password", map[string]string{"email": "a@b.com"}},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			w := DoJSON(env.Router, "POST", "/api/auth/login", tc.body)
			if w.Code != http.StatusBadRequest {
				t.Fatalf("Expected 400, got %d", w.Code)
			}
		})
	}
}

// ════════════════════════════════════════════════════════════
//  REFRESH TOKEN TESTS
// ════════════════════════════════════════════════════════════

func TestRefresh_Valid(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup to get tokens
	signup := map[string]string{
		"name":     "RefreshUser",
		"email":    "refresh@example.com",
		"password": "password123",
	}
	signupResp := DoJSON(env.Router, "POST", "/api/auth/signup", signup)
	cookie := ExtractCookie(signupResp, "refresh_token")
	if cookie == nil {
		t.Fatal("No refresh_token cookie after signup")
	}

	// Use refresh token
	w := DoJSONWithCookies(env.Router, "POST", "/api/auth/refresh", nil, []*http.Cookie{cookie})

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200, got %d: %s", w.Code, w.Body.String())
	}

	result := ParseJSON(w)
	if result["access_token"] == nil {
		t.Fatal("Expected new access_token")
	}

	// Should get a new refresh token cookie (rotation)
	newCookie := ExtractCookie(w, "refresh_token")
	if newCookie == nil {
		t.Fatal("Expected new refresh_token cookie after rotation")
	}
	if newCookie.Value == cookie.Value {
		t.Fatal("Expected refresh token to be rotated (different value)")
	}
}

func TestRefresh_InvalidToken(t *testing.T) {
	env := SetupTestEnv(t)

	fakeCookie := &http.Cookie{Name: "refresh_token", Value: "fake-token-id"}
	w := DoJSONWithCookies(env.Router, "POST", "/api/auth/refresh", nil, []*http.Cookie{fakeCookie})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestRefresh_NoCookie(t *testing.T) {
	env := SetupTestEnv(t)

	w := DoJSON(env.Router, "POST", "/api/auth/refresh", nil)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestRefresh_RevokedToken(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup
	signup := map[string]string{
		"name":     "RevokedUser",
		"email":    "revoked@example.com",
		"password": "password123",
	}
	signupResp := DoJSON(env.Router, "POST", "/api/auth/signup", signup)
	cookie := ExtractCookie(signupResp, "refresh_token")

	// Use the refresh token to rotate it (this revokes the old one)
	DoJSONWithCookies(env.Router, "POST", "/api/auth/refresh", nil, []*http.Cookie{cookie})

	// Try to use the OLD revoked token again
	w := DoJSONWithCookies(env.Router, "POST", "/api/auth/refresh", nil, []*http.Cookie{cookie})

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 for revoked token, got %d", w.Code)
	}
}

// ════════════════════════════════════════════════════════════
//  LOGOUT TESTS
// ════════════════════════════════════════════════════════════

func TestLogout_Valid(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup
	signup := map[string]string{
		"name":     "LogoutUser",
		"email":    "logout@example.com",
		"password": "password123",
	}
	signupResp := DoJSON(env.Router, "POST", "/api/auth/signup", signup)
	result := ParseJSON(signupResp)
	accessToken := result["access_token"].(string)
	cookie := ExtractCookie(signupResp, "refresh_token")

	// Logout
	headers := http.Header{"Authorization": {"Bearer " + accessToken}}
	w := DoJSONWithCookies(env.Router, "POST", "/api/auth/logout", nil, []*http.Cookie{cookie}, headers)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200, got %d: %s", w.Code, w.Body.String())
	}

	// Refresh should now fail
	w2 := DoJSONWithCookies(env.Router, "POST", "/api/auth/refresh", nil, []*http.Cookie{cookie})
	if w2.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 after logout, got %d", w2.Code)
	}
}

// ════════════════════════════════════════════════════════════
//  PROFILE TESTS
// ════════════════════════════════════════════════════════════

func TestProfile_Valid(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup
	signup := map[string]string{
		"name":      "ProfileUser",
		"email":     "profile@example.com",
		"password":  "password123",
		"shop_name": "Profile Shop",
	}
	signupResp := DoJSON(env.Router, "POST", "/api/auth/signup", signup)
	result := ParseJSON(signupResp)
	accessToken := result["access_token"].(string)

	// Get profile
	headers := http.Header{"Authorization": {"Bearer " + accessToken}}
	w := DoJSON(env.Router, "GET", "/api/me", nil, headers)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200, got %d: %s", w.Code, w.Body.String())
	}

	profile := ParseJSON(w)
	if profile["name"] != "ProfileUser" {
		t.Fatalf("Expected name 'ProfileUser', got %v", profile["name"])
	}
	if profile["email"] != "profile@example.com" {
		t.Fatalf("Expected email 'profile@example.com', got %v", profile["email"])
	}
	if profile["role"] != "owner" {
		t.Fatalf("Expected role 'owner', got %v", profile["role"])
	}
}

func TestProfile_NoToken(t *testing.T) {
	env := SetupTestEnv(t)

	w := DoJSON(env.Router, "GET", "/api/me", nil)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestProfile_InvalidToken(t *testing.T) {
	env := SetupTestEnv(t)

	headers := http.Header{"Authorization": {"Bearer invalid-token"}}
	w := DoJSON(env.Router, "GET", "/api/me", nil, headers)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

func TestProfile_MalformedHeader(t *testing.T) {
	env := SetupTestEnv(t)

	headers := http.Header{"Authorization": {"not-bearer-format"}}
	w := DoJSON(env.Router, "GET", "/api/me", nil, headers)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", w.Code)
	}
}

// ════════════════════════════════════════════════════════════
//  RATE LIMITING TESTS
// ════════════════════════════════════════════════════════════

func TestRateLimit_Signup(t *testing.T) {
	env := SetupTestEnv(t)

	// Signup rate limit is 5/min. Send 6 rapid requests.
	for i := 0; i < 6; i++ {
		body := map[string]string{
			"name":     fmt.Sprintf("User%d", i),
			"email":    fmt.Sprintf("ratelimit%d@example.com", i),
			"password": "password123",
		}
		w := DoJSON(env.Router, "POST", "/api/auth/signup", body)

		if i < 5 {
			// First 5 should succeed (201 or 409 depending on dups, but not 429)
			if w.Code == http.StatusTooManyRequests {
				t.Fatalf("Request %d should not be rate limited", i)
			}
		} else {
			// 6th should be rate limited
			if w.Code != http.StatusTooManyRequests {
				t.Fatalf("Request %d should be rate limited (429), got %d", i, w.Code)
			}
		}
	}
}

func TestRateLimit_Login(t *testing.T) {
	env := SetupTestEnv(t)

	// Login rate limit is 10/min. Send 11 rapid requests.
	for i := 0; i < 11; i++ {
		body := map[string]string{
			"email":    "ratelimit-login@example.com",
			"password": "password123",
		}
		w := DoJSON(env.Router, "POST", "/api/auth/login", body)

		if i < 10 {
			if w.Code == http.StatusTooManyRequests {
				t.Fatalf("Request %d should not be rate limited", i)
			}
		} else {
			if w.Code != http.StatusTooManyRequests {
				t.Fatalf("Request %d should be rate limited (429), got %d", i, w.Code)
			}
		}
	}
}
