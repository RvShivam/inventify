package handlers

import (
	"bytes"
	"crypto/rand"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/RvShivam/inventify/internal/crypto"
	"github.com/RvShivam/inventify/internal/events"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Request/response DTOs
type createWooReq struct {
	Name           string `json:"name"` // optional
	SiteURL        string `json:"site_url" binding:"required,url"`
	ConsumerKey    string `json:"consumer_key" binding:"required"`
	ConsumerSecret string `json:"consumer_secret" binding:"required"`
	// VerifySSL optional; default true when omitted
	VerifySSL *bool `json:"verify_ssl"`
}

// Simple response (masked)
type wooStoreResp struct {
	ID           uint      `json:"id"`
	Name         string    `json:"name"`
	SiteURL      string    `json:"site_url"`
	IsActive     bool      `json:"is_active"`
	LastSyncedAt time.Time `json:"last_synced_at"`
}

// CreateWooStore tests keys, encrypts secrets and saves WooStore
func CreateWooStore(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req createWooReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		site := strings.TrimRight(req.SiteURL, "/")
		if !strings.HasPrefix(site, "https://") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "site_url must be HTTPS"})
			return
		}
		verifySSL := true
		if req.VerifySSL != nil {
			verifySSL = *req.VerifySSL
		}

		ok, permErr := testWooConnection(site, req.ConsumerKey, req.ConsumerSecret, verifySSL)
		if !ok {
			msg := "failed to validate credentials"
			if permErr != nil {
				msg = permErr.Error()
			}
			c.JSON(http.StatusBadRequest, gin.H{"error": msg})
			return
		}

		// Encrypt keys
		appKey := []byte(os.Getenv("APP_SECRET_KEY"))
		ckEnc, err := crypto.Encrypt(req.ConsumerKey, appKey)
		if err != nil {
			log.Printf("ERROR encrypting consumer key: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "encryption failed"})
			return
		}
		csEnc, err := crypto.Encrypt(req.ConsumerSecret, appKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "encryption failed"})
			return
		}

		// OrganizationID retrieval — implement your auth->org mapping
		orgID, okOrg := getOrgIDFromContext(c)
		if !okOrg {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "organization not found in context"})
			return
		}

		// determine name: use req.Name if provided, otherwise auto-generate from site
		name := strings.TrimSpace(req.Name)
		if name == "" {
			name = generateNameFromSite(site)
			if name == "" {
				name = "woo-store"
			}
			// ensure unique per organization
			uniqueName, err := makeUniqueStoreName(db, orgID, name)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error generating store name"})
				return
			}
			name = uniqueName
		}

		// truncate name to reasonable length (optional, e.g., 120 chars)
		if len(name) > 120 {
			name = name[:120]
		}

		store := models.WooStore{
			OrganizationID:          orgID,
			Name:                    name,
			SiteURL:                 site,
			ConsumerKeyEncrypted:    ckEnc,
			ConsumerSecretEncrypted: csEnc,
			VerifySSL:               verifySSL,
			IsActive:                true,
			LastSyncedAt:            ptrTime(time.Now()),
		}

		if err := db.Create(&store).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save store"})
			return
		}

		// Ensure the "woocommerce" channel exists for this org
		go ensureWooChannel(db, orgID)

		// Publish RabbitMQ event (non-blocking; log if fails)
		go func() {
			ev := events.WooStoreConnectedEvent{
				BaseEvent: events.BaseEvent{
					Event:     "woo.store.connected",
					Version:   1,
					Timestamp: time.Now().UTC(),
				},
				StoreID:        store.ID,
				OrganizationID: store.OrganizationID,
				SiteURL:        store.SiteURL,
			}
			if err := events.Publish("woo.store.connected", ev); err != nil {
				log.Println("RabbitMQ publish error:", err)
			}
		}()

		resp := wooStoreResp{
			ID:           store.ID,
			Name:         store.Name,
			SiteURL:      store.SiteURL,
			IsActive:     store.IsActive,
			LastSyncedAt: time.Now(),
		}
		c.JSON(http.StatusCreated, resp)
	}
}

// TestWooStore - re-validate stored keys (load store by id)
func TestWooStore(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var store models.WooStore
		if err := db.First(&store, id).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "store not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
			return
		}

		appKey := []byte(os.Getenv("APP_SECRET_KEY"))
		ck, err := crypto.Decrypt(store.ConsumerKeyEncrypted, appKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "decrypt failed"})
			return
		}
		cs, err := crypto.Decrypt(store.ConsumerSecretEncrypted, appKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "decrypt failed"})
			return
		}

		ok, permErr := testWooConnection(store.SiteURL, ck, cs, store.VerifySSL)
		if !ok {
			msg := "validation failed"
			if permErr != nil {
				msg = permErr.Error()
			}
			c.JSON(http.StatusBadRequest, gin.H{"error": msg})
			return
		}

		// update last synced
		now := time.Now()
		store.LastSyncedAt = &now
		_ = db.Save(&store)

		// Ensure the "woocommerce" channel exists (self-healing)
		go ensureWooChannel(db, store.OrganizationID)

		c.JSON(http.StatusOK, gin.H{"ok": true})
	}
}

// Register webhooks for a store
type registerWebhooksReq struct {
	DeliveryURL string   `json:"delivery_url" binding:"required,url"`
	Topics      []string `json:"topics" binding:"required"`
}

func RegisterWooWebhooks(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var store models.WooStore
		if err := db.First(&store, id).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "store not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
			return
		}

		var req registerWebhooksReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		appKey := []byte(os.Getenv("APP_SECRET_KEY"))
		ck, err := crypto.Decrypt(store.ConsumerKeyEncrypted, appKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "decrypt failed"})
			return
		}
		cs, err := crypto.Decrypt(store.ConsumerSecretEncrypted, appKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "decrypt failed"})
			return
		}

		created := make([]models.WooStoreWebhook, 0, len(req.Topics))
		for _, topic := range req.Topics {
			secret := randomSecret(32)
			webhookID, err := createWooWebhook(store.SiteURL, ck, cs, req.DeliveryURL, topic, secret, store.VerifySSL)
			if err != nil {
				// On failure, return error and do NOT attempt cleanup (caller may retry)
				c.JSON(http.StatusBadGateway, gin.H{"error": fmt.Sprintf("failed to create webhook: %v", err)})
				return
			}

			// encrypt secret before storing
			secretEnc, err := crypto.Encrypt(secret, appKey)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "encryption failed"})
				return
			}

			ws := models.WooStoreWebhook{
				WooStoreID:      store.ID,
				WebhookID:       webhookID,
				Topic:           topic,
				DeliveryURL:     req.DeliveryURL,
				SecretEncrypted: secretEnc,
				Active:          true,
			}
			if err := db.Create(&ws).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error saving webhook"})
				return
			}
			created = append(created, ws)
		}

		c.JSON(http.StatusOK, gin.H{"created": created})
	}
}

/* ------------------------------
   Helper functions
   ------------------------------ */

// testWooConnection: tries a read (products) and returns ok + optional permission error
func testWooConnection(site, consumerKey, consumerSecret string, verifySSL bool) (bool, error) {
	url := fmt.Sprintf("%s/wp-json/wc/v3/products?per_page=1", strings.TrimRight(site, "/"))
	req, _ := http.NewRequest("GET", url, nil)
	req.SetBasicAuth(consumerKey, consumerSecret)

	client := &http.Client{Timeout: 10 * time.Second}
	if !verifySSL {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}
	resp, err := client.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return true, nil
	}
	// 401/403 => likely bad creds or insufficient perms
	if resp.StatusCode == 401 || resp.StatusCode == 403 {
		body, _ := io.ReadAll(resp.Body)
		return false, fmt.Errorf("authentication failed (%d): %s", resp.StatusCode, string(body))
	}
	return false, fmt.Errorf("unexpected status: %d", resp.StatusCode)
}

// createWooWebhook: creates a webhook and returns the webhook id (string)
func createWooWebhook(site, consumerKey, consumerSecret, deliveryURL, topic, secret string, verifySSL bool) (string, error) {
	url := fmt.Sprintf("%s/wp-json/wc/v3/webhooks", strings.TrimRight(site, "/"))

	payload := map[string]interface{}{
		"name":         "inventify-" + topic,
		"topic":        topic,
		"delivery_url": deliveryURL,
		"secret":       secret,
		"status":       "active",
	}
	b, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(b))
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(consumerKey, consumerSecret)

	client := &http.Client{Timeout: 10 * time.Second}
	if !verifySSL {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 201 && resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("webhook create returned %d: %s", resp.StatusCode, string(body))
	}
	var respJSON map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&respJSON); err != nil {
		return "", err
	}
	// woo returns id field (number or string); normalize to string
	if id, ok := respJSON["id"]; ok {
		return fmt.Sprintf("%v", id), nil
	}
	return "", errors.New("no id in webhook response")
}

// getWooWebhookID finds a webhook by topic and delivery_url
func getWooWebhookID(site, consumerKey, consumerSecret, topic, deliveryURL string, verifySSL bool) (string, error) {
	// List webhooks (filtering by topic if possible, but Woo V3 doesn't always support strict filtering by topic in list, so we might need to fetch all or filter manually)
	// V3 supports ?status=active etc. Let's just fetch all (default 10) or increase limit.
	// Better: ?topic=... is supported in some versions. Let's try listing.
	url := fmt.Sprintf("%s/wp-json/wc/v3/webhooks?per_page=100", strings.TrimRight(site, "/"))
	req, _ := http.NewRequest("GET", url, nil)
	req.SetBasicAuth(consumerKey, consumerSecret)

	client := &http.Client{Timeout: 15 * time.Second}
	if !verifySSL {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("failed to list webhooks: %d", resp.StatusCode)
	}

	var webhooks []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&webhooks); err != nil {
		return "", err
	}

	for _, wh := range webhooks {
		t, _ := wh["topic"].(string)
		d, _ := wh["delivery_url"].(string)
		if t == topic && d == deliveryURL {
			if id, ok := wh["id"]; ok {
				return fmt.Sprintf("%v", id), nil
			}
		}
	}
	return "", nil // not found
}

// deleteWooWebhook deletes a webhook by ID
func deleteWooWebhook(site, consumerKey, consumerSecret, webhookID string, verifySSL bool) error {
	url := fmt.Sprintf("%s/wp-json/wc/v3/webhooks/%s?force=true", strings.TrimRight(site, "/"), webhookID)
	req, _ := http.NewRequest("DELETE", url, nil)
	req.SetBasicAuth(consumerKey, consumerSecret)

	client := &http.Client{Timeout: 15 * time.Second}
	if !verifySSL {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 204 { // 200 or 204 is success
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete webhook %s: %d %s", webhookID, resp.StatusCode, string(body))
	}
	return nil
}

// randomSecret returns a url-safe base64-like secret (hex)
func randomSecret(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return fmt.Sprintf("%x", b)
}

// ptrTime helper
func ptrTime(t time.Time) *time.Time { return &t }

// getOrgIDFromContext
func getOrgIDFromContext(c *gin.Context) (uint, bool) {

	v, ok := c.Get("org_Id")
	if !ok {
		return 0, false
	}
	if id, ok := v.(uint); ok {
		return id, true
	}
	// if your middleware stores int64 or int:
	if id2, ok := v.(int); ok {
		return uint(id2), true
	}
	return 0, false
}

// generateNameFromSite extracts a friendly name from a site URL.
// e.g. https://store.example.com/path -> store.example.com
func generateNameFromSite(site string) string {
	u, err := url.Parse(site)
	if err != nil || u.Host == "" {
		// fallback: sanitize input
		s := strings.TrimPrefix(strings.TrimSpace(site), "https://")
		s = strings.TrimPrefix(s, "http://")
		s = strings.TrimRight(s, "/")
		// remove path if any
		if idx := strings.Index(s, "/"); idx >= 0 {
			s = s[:idx]
		}
		return s
	}
	host := u.Hostname() // strips port
	// remove leading www.
	host = strings.TrimPrefix(host, "www.")
	return host
}

// makeUniqueStoreName checks the DB for existing names in the same org and
// returns a unique name by appending -1, -2... if needed.
func makeUniqueStoreName(db *gorm.DB, orgID uint, base string) (string, error) {
	name := base
	var count int64
	suffix := 0
	for {
		// count existing stores with same name for org
		if err := db.Model(&models.WooStore{}).
			Where("organization_id = ? AND name = ?", orgID, name).
			Count(&count).Error; err != nil {
			return "", err
		}
		if count == 0 {
			return name, nil
		}
		suffix++
		name = base + "-" + strconv.Itoa(suffix)
	}
}

// ensureWooChannel ensures that a "woocommerce" channel exists for the organization.
func ensureWooChannel(db *gorm.DB, orgID uint) {
	var count int64
	if err := db.Model(&models.Channel{}).Where("organization_id = ? AND name = ?", orgID, "woocommerce").Count(&count).Error; err != nil {
		log.Printf("Error checking for woocommerce channel: %v", err)
		return
	}
	if count == 0 {
		channel := models.Channel{
			OrganizationID: orgID,
			Name:           "woocommerce",
			Type:           "ecommerce",
			IsActive:       true,
		}
		if err := db.Create(&channel).Error; err != nil {
			log.Printf("Error creating woocommerce channel: %v", err)
		} else {
			log.Printf("Created 'woocommerce' channel for org %d", orgID)
		}
	}
}
