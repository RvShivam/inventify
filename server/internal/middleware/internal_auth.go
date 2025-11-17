package middleware

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

// extractServiceToken returns token from either Service-Token header or Authorization: Bearer <token>
func extractServiceTokenFromHeaders(c *gin.Context) string {
	// Prefer explicit Service-Token header
	if t := strings.TrimSpace(c.GetHeader("Service-Token")); t != "" {
		return t
	}

	// Fallback to Authorization: Bearer <token>
	auth := strings.TrimSpace(c.GetHeader("Authorization"))
	if auth == "" {
		return ""
	}
	parts := strings.SplitN(auth, " ", 2)
	if len(parts) != 2 {
		return ""
	}
	if strings.ToLower(parts[0]) != "bearer" {
		return ""
	}
	return strings.TrimSpace(parts[1])
}

// RequireServiceToken enforces that the caller provides the configured SERVICE_TOKEN
// either via Service-Token header or Authorization: Bearer <token>.
func RequireServiceToken() gin.HandlerFunc {
	expected := strings.TrimSpace(os.Getenv("SERVICE_TOKEN"))

	return func(c *gin.Context) {
		// fail-safe: if the server isn't configured with a token, return 500 so ops notices.
		if expected == "" {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "SERVICE_TOKEN not configured"})
			return
		}

		token := extractServiceTokenFromHeaders(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing service token"})
			return
		}

		if token != expected {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}

		// mark the request as internal (useful for handlers)
		c.Set("internal_request", true)

		c.Next()
	}
}
