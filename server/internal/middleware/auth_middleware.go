package middleware

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// RequireAuth is a middleware to protect routes
func RequireAuth(c *gin.Context) {
	// Get the token from the Authorization header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
		return
	}

	tokenString := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenString == authHeader {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
		return
	}

	// Parse and validate the token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			return nil, fmt.Errorf("server misconfiguration: missing JWT_SECRET")
		}
		return []byte(secret), nil
	})

	if err != nil {
		// token parsing failed
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token", "details": err.Error()})
		return
	}

	if token == nil || token.Claims == nil {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token: empty claims"})
		return
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
		return
	}

	// Expiry check (defensive)
	if expRaw, found := claims["exp"]; found {
		switch exp := expRaw.(type) {
		case float64:
			if time.Now().Unix() > int64(exp) {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token has expired"})
				return
			}
		case int64:
			if time.Now().Unix() > exp {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token has expired"})
				return
			}
		default:
			// can't interpret exp; ignore expiry check but log for debugging
			log.Printf("[RequireAuth] warning: cannot parse exp claim type=%T value=%v", expRaw, expRaw)
		}
	}

	// userId (defensive)
	if subRaw, found := claims["sub"]; found {
		switch v := subRaw.(type) {
		case float64:
			c.Set("user_Id", uint(v))
		case int64:
			c.Set("user_Id", uint(v))
		case string:
			if n, err := strconv.ParseUint(v, 10, 64); err == nil {
				c.Set("user_Id", uint(n))
			}
		default:
			// ignore if unknown type
			log.Printf("[RequireAuth] warning: unexpected sub claim type=%T value=%v", subRaw, subRaw)
		}
	}

	// orgId: prefer claim, fallback to header
	var orgIDSet bool
	if orgRaw, ok := claims["org_id"]; ok {
		switch v := orgRaw.(type) {
		case float64:
			c.Set("org_Id", uint(v))
			orgIDSet = true
		case int64:
			c.Set("org_Id", uint(v))
			orgIDSet = true
		case string:
			if n, err := strconv.Atoi(v); err == nil {
				c.Set("org_Id", uint(n))
				orgIDSet = true
			}
		default:
			log.Printf("[RequireAuth] warning: unexpected org_id claim type=%T value=%v", orgRaw, orgRaw)
		}
	}

	if !orgIDSet {
		// fallback to header
		orgHdr := c.GetHeader("X-Organization-Id")
		if orgHdr == "" {
			// not fatal here — some endpoints might not require org, but in your app it is required
			// return unauthorized to match previous behavior
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "organization not found in context"})
			return
		}
		if n, err := strconv.Atoi(orgHdr); err == nil {
			c.Set("orgId", uint(n))
			orgIDSet = true
		} else {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "invalid X-Organization-Id header"})
			return
		}
	}

	// At this point we have either set userId and orgId (if present). Continue.
	c.Next()
}
