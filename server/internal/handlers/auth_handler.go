package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/RvShivam/inventify/internal/config"
	"github.com/RvShivam/inventify/internal/services"
)

type AuthHandler struct {
	authService *services.AuthService
	cfg         *config.Config
}

func NewAuthHandler(authService *services.AuthService, cfg *config.Config) *AuthHandler {
	return &AuthHandler{authService: authService, cfg: cfg}
}

// Signup handles POST /api/auth/signup
func (h *AuthHandler) Signup(c *gin.Context) {
	var req services.SignupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	tokens, userID, err := h.authService.Signup(req)
	if err != nil {
		switch err {
		case services.ErrEmailTaken:
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		case services.ErrInvalidReferral:
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create account"})
		}
		return
	}

	// Set refresh token as HTTP-only cookie
	h.setRefreshCookie(c, tokens.RefreshToken)

	c.JSON(http.StatusCreated, gin.H{
		"message":      "Account created successfully",
		"user_id":      userID,
		"access_token": tokens.AccessToken,
	})
}

// Login handles POST /api/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req services.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	tokens, profile, err := h.authService.Login(req)
	if err != nil {
		if err == services.ErrInvalidCredentials {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Login failed"})
		}
		return
	}

	h.setRefreshCookie(c, tokens.RefreshToken)

	c.JSON(http.StatusOK, gin.H{
		"access_token": tokens.AccessToken,
		"user":         profile,
	})
}

// Refresh handles POST /api/auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	refreshTokenID, err := c.Cookie("refresh_token")
	if err != nil || refreshTokenID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No refresh token provided"})
		return
	}

	tokens, err := h.authService.RefreshTokens(refreshTokenID)
	if err != nil {
		h.clearRefreshCookie(c)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired refresh token"})
		return
	}

	h.setRefreshCookie(c, tokens.RefreshToken)

	c.JSON(http.StatusOK, gin.H{
		"access_token": tokens.AccessToken,
	})
}

// Logout handles POST /api/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	refreshTokenID, _ := c.Cookie("refresh_token")
	if refreshTokenID != "" {
		_ = h.authService.Logout(refreshTokenID)
	}

	h.clearRefreshCookie(c)

	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}

// GetProfile handles GET /api/me
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	profile, err := h.authService.GetProfile(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, profile)
}

// ── Cookie helpers ─────────────────────────────────────────

func (h *AuthHandler) setRefreshCookie(c *gin.Context, token string) {
	c.SetCookie(
		"refresh_token",
		token,
		int(h.cfg.RefreshTokenExpiry.Seconds()),
		"/api/auth",
		"",    // domain (empty = current)
		false, // secure (set to true in production with HTTPS)
		true,  // httpOnly
	)
}

func (h *AuthHandler) clearRefreshCookie(c *gin.Context) {
	c.SetCookie("refresh_token", "", -1, "/api/auth", "", false, true)
}

// GetUserID is a helper that handlers can use to extract the authenticated user ID.
func GetUserID(c *gin.Context) (uint, bool) {
	val, exists := c.Get("user_id")
	if !exists {
		return 0, false
	}
	id, ok := val.(uint)
	return id, ok
}

// GetOrgID is a helper that handlers can use to extract the authenticated org ID.
func GetOrgID(c *gin.Context) (uint, bool) {
	val, exists := c.Get("org_id")
	if !exists {
		return 0, false
	}
	id, ok := val.(uint)
	return id, ok
}

// respondError is a generic helper for returning error responses.
func respondError(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"error": message})
}

// respondErrorFromTime is a generic helper for returning error responses with a retry-after header.
func respondErrorRetryAfter(c *gin.Context, retryAfter time.Duration) {
	c.Header("Retry-After", retryAfter.String())
	c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests"})
}
