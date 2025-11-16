package handlers

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/RvShivam/inventify/internal/crypto"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Request bodies for internal endpoints
type registerWebhooksInternalReq struct {
	DeliveryURL string   `json:"delivery_url,omitempty"`
	Topics      []string `json:"topics,omitempty"`
}

type syncCategoriesResp struct {
	Imported int `json:"imported"`
	Skipped  int `json:"skipped"`
}

// SyncWooCategories: fetches categories from the Woo store and writes Category + CategoryMapping.
// Protected endpoint for worker usage; ensure it's mounted with RequireServiceToken middleware.
func SyncWooCategories(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// get store id
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

		// decrypt keys
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

		// fetch categories from Woo
		wooCats, err := fetchWooCategories(store.SiteURL, ck, cs, store.VerifySSL)
		if err != nil {
			c.JSON(http.StatusBadGateway, gin.H{"error": "failed to fetch categories", "detail": err.Error()})
			return
		}

		imported := 0
		skipped := 0
		// iterate and upsert into Category & CategoryMapping
		for _, wc := range wooCats {
			// find or create Category by name (case-insensitive)
			var cat models.Category
			name := strings.TrimSpace(wc.Name)
			if name == "" {
				// skip empty names
				skipped++
				continue
			}
			err := db.Where("LOWER(name) = LOWER(?)", name).First(&cat).Error
			if errors.Is(err, gorm.ErrRecordNotFound) {
				// create new category
				cat = models.Category{
					Name:        name,
					Description: wc.Description,
				}
				if err := db.Create(&cat).Error; err != nil {
					// skip on error but continue
					skipped++
					continue
				}
			} else if err != nil {
				// DB error
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error", "detail": err.Error()})
				return
			}

			// create mapping if not exists
			var mapping models.CategoryMapping
			if err := db.Where("category_id = ? AND channel = ? AND channel_category_id = ?", cat.ID, "woocommerce", fmt.Sprintf("%d", wc.ID)).First(&mapping).Error; errors.Is(err, gorm.ErrRecordNotFound) {
				// not found -> create
				mapping = models.CategoryMapping{
					CategoryID:        cat.ID,
					Channel:           "woocommerce",
					ChannelCategoryID: fmt.Sprintf("%d", wc.ID),
					IsDefault:         false,
				}
				if err := db.Create(&mapping).Error; err != nil {
					// ignore duplicate constraint or other transient error and continue
					skipped++
					continue
				}
				imported++
			} else if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error", "detail": err.Error()})
				return
			} else {
				// mapping exists -> skip
				skipped++
			}
		}

		// update store last synced
		now := time.Now()
		store.LastSyncedAt = &now
		_ = db.Save(&store)

		c.JSON(http.StatusOK, syncCategoriesResp{Imported: imported, Skipped: skipped})
	}
}

// InternalRegisterWebhooks idempotently creates webhooks for a Woo store.
// Accepts an optional delivery_url & topics array in the body.
func InternalRegisterWebhooks(db *gorm.DB) gin.HandlerFunc {
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

		var req registerWebhooksInternalReq
		_ = c.ShouldBindJSON(&req) // optional body

		// calculate delivery URL
		deliveryURL := strings.TrimSpace(req.DeliveryURL)
		if deliveryURL == "" {
			// try env WEBHOOK_DELIVERY_URL or WEBHOOK_BASE
			if env := os.Getenv("WEBHOOK_DELIVERY_URL"); env != "" {
				deliveryURL = strings.TrimRight(env, "/")
			} else if base := os.Getenv("WEBHOOK_BASE"); base != "" {
				deliveryURL = strings.TrimRight(base, "/") + "/webhooks/woo"
			} else {
				// fallback: require delivery URL if not set in env
				c.JSON(http.StatusBadRequest, gin.H{"error": "delivery_url not provided and WEBHOOK_DELIVERY_URL/WEBHOOK_BASE not set"})
				return
			}
		}

		// topics default
		topics := req.Topics
		if len(topics) == 0 {
			topics = []string{"product.created", "product.updated", "product.deleted", "order.created", "order.updated"}
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

		created := make([]models.WooStoreWebhook, 0, len(topics))
		skipped := 0
		for _, topic := range topics {
			// check if we already have webhook for this store/topic/delivery_url
			var existing models.WooStoreWebhook
			err := db.Where("woo_store_id = ? AND topic = ? AND delivery_url = ?", store.ID, topic, deliveryURL).First(&existing).Error
			if err == nil {
				// exists -> skip
				skipped++
				continue
			}
			if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error", "detail": err.Error()})
				return
			}

			// create webhook on Woo
			secret := randomSecret(32)
			webhookID, err := createWooWebhook(store.SiteURL, ck, cs, deliveryURL, topic, secret, store.VerifySSL)
			if err != nil {
				c.JSON(http.StatusBadGateway, gin.H{"error": fmt.Sprintf("failed to create webhook on woo: %v", err)})
				return
			}

			// encrypt secret
			secretEnc, err := crypto.Encrypt(secret, appKey)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "encryption failed"})
				return
			}

			ws := models.WooStoreWebhook{
				WooStoreID:      store.ID,
				WebhookID:       webhookID,
				Topic:           topic,
				DeliveryURL:     deliveryURL,
				SecretEncrypted: secretEnc,
				Active:          true,
			}
			if err := db.Create(&ws).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error saving webhook", "detail": err.Error()})
				return
			}
			created = append(created, ws)
		}

		// return details
		c.JSON(http.StatusOK, gin.H{
			"created": created,
			"skipped": skipped,
		})
	}
}

/* ----------------------------
   Helper: fetch categories from Woo
   ---------------------------- */

// wooCategory is a small struct matching the Woo REST response for categories
type wooCategory struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Slug        string `json:"slug"`
	Description string `json:"description"`
	Parent      int    `json:"parent"`
	Count       int    `json:"count"`
}

// fetchWooCategories retrieves categories list from the Woo REST API
func fetchWooCategories(site, consumerKey, consumerSecret string, verifySSL bool) ([]wooCategory, error) {
	url := fmt.Sprintf("%s/wp-json/wc/v3/products/categories?per_page=100", strings.TrimRight(site, "/"))
	req, _ := http.NewRequest("GET", url, nil)
	req.SetBasicAuth(consumerKey, consumerSecret)

	// support simple HTTP client with optional insecure skip verify
	client := &http.Client{Timeout: 15 * time.Second}
	if !verifySSL {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
		client.Transport = tr
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("woo categories returned %d: %s", resp.StatusCode, string(body))
	}

	var out []wooCategory
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return out, nil
}
