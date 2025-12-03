package handlers

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/RvShivam/inventify/internal/crypto"
	"github.com/RvShivam/inventify/internal/events"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// WooWebhookReceiver handles incoming WooCommerce webhooks posted to /webhooks/woo.
// - Verifies signature from X-WC-Webhook-Signature (base64 HMAC-SHA256 of raw body).
// - Finds the corresponding WooStoreWebhook (by X-WC-Webhook-ID or delivery URL).
// - Publishes an internal event "woo.webhook.received" (best-effort).
func WooWebhookReceiver(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Read raw body
		body, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "failed to read body"})
			return
		}

		// Headers Woo commonly sends
		signature := c.GetHeader("X-WC-Webhook-Signature")
		webhookIDHeader := c.GetHeader("X-WC-Webhook-ID")
		// Some installs set topic header
		topic := c.GetHeader("X-WC-Webhook-Topic")

		// Try to find webhook DB record
		var ws models.WooStoreWebhook
		found := false
		if webhookIDHeader != "" {
			// Try find by webhook id
			if err := db.Where("webhook_id = ?", webhookIDHeader).First(&ws).Error; err == nil {
				found = true
			} else if !errors.Is(err, gorm.ErrRecordNotFound) {
				// DB error
				log.Println("woo webhook receiver: db error lookup by webhook_id:", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
				return
			}
		}

		if !found {
			// fallback: match by delivery URL (the request host+path should match a stored delivery_url)
			// Build the full request URL (scheme + host + path)
			reqURL := getRequestPublicURL(c)
			if reqURL != "" {
				// 1. Try exact match
				if err := db.Where("delivery_url = ?", reqURL).First(&ws).Error; err == nil {
					found = true
				} else if !errors.Is(err, gorm.ErrRecordNotFound) {
					log.Println("woo webhook receiver: db error lookup by delivery_url:", err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
					return
				}

				// 2. If not found, try matching without scheme (http vs https issues)
				if !found {
					// Strip scheme from reqURL
					reqNoScheme := reqURL
					if idx := strings.Index(reqURL, "://"); idx >= 0 {
						reqNoScheme = reqURL[idx+3:]
					}
					// Search for delivery_url ending with this host+path
					// This is a bit loose but safe enough if secrets are verified
					if err := db.Where("delivery_url LIKE ?", "%://"+reqNoScheme).First(&ws).Error; err == nil {
						found = true
					}
				}
			}
		}

		if !found {
			// Not found: still respond 404 since we cannot verify signature or associate secret
			log.Printf("woo webhook receiver: webhook record not found (webhook_id=%q path=%s)", webhookIDHeader, c.Request.URL.Path)
			c.JSON(http.StatusNotFound, gin.H{"error": "webhook not registered"})
			return
		}

		// Decrypt secret
		appKey := []byte(os.Getenv("APP_SECRET_KEY"))
		if len(appKey) == 0 {
			log.Println("woo webhook receiver: APP_SECRET_KEY not set")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "server misconfigured"})
			return
		}
		secret, err := crypto.Decrypt(ws.SecretEncrypted, appKey)
		if err != nil {
			log.Println("woo webhook receiver: failed to decrypt secret:", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "server error"})
			return
		}

		// Verify signature if provided
		if signature == "" {
			// No signature header present — treat as unauthorized
			log.Println("woo webhook receiver: missing X-WC-Webhook-Signature header")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "missing signature"})
			return
		}

		if !verifyWooSignature(secret, body, signature) {
			log.Println("woo webhook receiver: signature verification failed")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid signature"})
			return
		}

		// Optionally parse JSON to ensure it's valid (we still publish raw payload)
		var payload interface{}
		if len(body) > 0 {
			if err := json.Unmarshal(body, &payload); err != nil {
				// don't error out — still accept but log
				log.Println("woo webhook receiver: warning: payload is not valid JSON:", err)
				payload = string(body) // fallback to raw
			}
		}

		// Build internal event
		internalEvent := map[string]interface{}{
			"event":             "woo.webhook.received",
			"version":           1,
			"timestamp":         time.Now().UTC().Format(time.RFC3339),
			"woo_store_webhook": map[string]interface{}{"id": ws.ID, "webhook_id": ws.WebhookID, "topic": ws.Topic, "delivery_url": ws.DeliveryURL},
			"topic":             topic,
			"payload":           payload,
		}

		// Publish to RabbitMQ (best-effort). Log error but still respond 200.
		if err := events.Publish("woo.webhook.received", internalEvent); err != nil {
			log.Println("woo webhook receiver: failed to publish event:", err)
		}

		// Respond 200 quickly
		c.Status(http.StatusOK)
	}
}

// verifyWooSignature expects Woo signature (base64-encoded HMAC-SHA256 of raw body)
func verifyWooSignature(secret string, body []byte, signatureHeader string) bool {
	// Woo sends base64(hmac_sha256(body, secret))
	// signatureHeader may come URL-encoded or padded, we'll decode before compare.
	decodedHeader, err := base64.StdEncoding.DecodeString(strings.TrimSpace(signatureHeader))
	if err != nil {
		// sometimes Woo sends signature in hex? unlikely — log and fail
		log.Println("woo webhook receiver: signature base64 decode failed:", err)
		return false
	}

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := mac.Sum(nil)

	// Use hmac.Equal for timing-safe comparison
	return hmac.Equal(expected, decodedHeader)
}

// getRequestPublicURL reconstructs the full public delivery URL used for DB matching
// e.g., https://abcd.ngrok.app/webhooks/woo
func getRequestPublicURL(c *gin.Context) string {
	// prefer x-forwarded proto if set (ngrok and proxies may set it)
	proto := c.Request.Header.Get("X-Forwarded-Proto")
	if proto == "" {
		if c.Request.TLS != nil {
			proto = "https"
		} else {
			// fallback to scheme from request (may be http if ngrok forwards as http)
			proto = "http"
		}
	}
	host := c.Request.Host
	path := c.Request.URL.Path
	return proto + "://" + host + path
}
