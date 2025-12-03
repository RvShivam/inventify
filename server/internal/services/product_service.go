package services

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/RvShivam/inventify/internal/crypto"
	"github.com/RvShivam/inventify/internal/models"
	"gorm.io/gorm"
)

type ProductService struct {
	db *gorm.DB
}

func NewProductService(db *gorm.DB) *ProductService {
	return &ProductService{db: db}
}

// SyncProductToWoo syncs a local product to WooCommerce
func (s *ProductService) SyncProductToWoo(productID uint) error {
	// 1. Fetch Product with all necessary preloads
	var product models.Product
	if err := s.db.Preload("Images").Preload("ProductWoo").Preload("LocalCategory").First(&product, productID).Error; err != nil {
		return fmt.Errorf("failed to fetch product: %w", err)
	}

	// 2. Check if Woo is enabled for this product
	// We can check ProductChannels or just rely on ProductWoo existence/config
	// For now, let's assume if ProductWoo exists, we try to sync.
	// In a real scenario, we should check models.ProductChannel IsEnabled.
	var pc models.ProductChannel
	// Find Woo channel ID
	var wooChannel models.Channel
	if err := s.db.Where("name = ? AND organization_id = ?", "woocommerce", product.OrganizationID).First(&wooChannel).Error; err != nil {
		return fmt.Errorf("woocommerce channel not found for org: %w", err)
	}

	if err := s.db.Where("product_id = ? AND channel_id = ? AND is_enabled = ?", product.ID, wooChannel.ID, true).First(&pc).Error; err != nil {
		return fmt.Errorf("woocommerce channel not enabled for this product")
	}

	// 3. Get Active WooStore credentials
	var store models.WooStore
	if err := s.db.Where("organization_id = ? AND is_active = ?", product.OrganizationID, true).First(&store).Error; err != nil {
		return fmt.Errorf("no active woocommerce store found: %w", err)
	}

	// Decrypt keys
	appKey := []byte(os.Getenv("APP_SECRET_KEY"))
	ck, err := crypto.Decrypt(store.ConsumerKeyEncrypted, appKey)
	if err != nil {
		return fmt.Errorf("failed to decrypt consumer key: %w", err)
	}
	cs, err := crypto.Decrypt(store.ConsumerSecretEncrypted, appKey)
	if err != nil {
		return fmt.Errorf("failed to decrypt consumer secret: %w", err)
	}

	// 4. Construct Payload
	payload := map[string]interface{}{
		"name":              product.Name,
		"short_description": product.ShortDescription,
		"description":       product.Description,
		"sku":               product.SKU,
		"regular_price":     fmt.Sprintf("%.2f", product.RegularPrice),
		"manage_stock":      product.ManageStock,
		"stock_quantity":    product.StockQuantity,
	}

	if product.SalePrice != nil {
		payload["sale_price"] = fmt.Sprintf("%.2f", *product.SalePrice)
	}

	if product.WeightKg != nil {
		payload["weight"] = fmt.Sprintf("%.2f", *product.WeightKg)
	}
	// Dimensions
	dimensions := make(map[string]string)
	if product.LengthCm != nil {
		dimensions["length"] = fmt.Sprintf("%.2f", *product.LengthCm)
	}
	if product.WidthCm != nil {
		dimensions["width"] = fmt.Sprintf("%.2f", *product.WidthCm)
	}
	if product.HeightCm != nil {
		dimensions["height"] = fmt.Sprintf("%.2f", *product.HeightCm)
	}
	if len(dimensions) > 0 {
		payload["dimensions"] = dimensions
	}

	// Images
	if len(product.Images) > 0 {
		var images []map[string]string
		// Note: Woo requires public URLs. If we are localhost, this won't work for local images unless we use ngrok or similar.
		// For now, we'll send the relative path, which Woo will likely reject or fail to fetch.
		// In production, this should be a full URL.
		// We will try to construct a full URL if BACKEND_URL is set.
		baseURL := os.Getenv("BACKEND_URL")
		if baseURL == "" {
			baseURL = "http://localhost:8080"
		}
		for _, img := range product.Images {
			fullSrc := img.Src
			if !strings.HasPrefix(fullSrc, "http") {
				fullSrc = strings.TrimRight(baseURL, "/") + img.Src
			}
			images = append(images, map[string]string{
				"src":      fullSrc,
				"position": fmt.Sprintf("%d", img.Position),
			})
		}
		payload["images"] = images
	}

	// Categories
	// We need to map LocalCategoryID to Woo Category ID
	if product.LocalCategoryID != nil {
		var mapping models.CategoryMapping
		if err := s.db.Where("category_id = ? AND channel = ?", *product.LocalCategoryID, "woocommerce").First(&mapping).Error; err == nil {
			// Found mapping
			payload["categories"] = []map[string]interface{}{
				{"id": mapping.ChannelCategoryID}, // Woo expects ID, sometimes int, sometimes string depending on version, usually int in JSON
			}
			// Note: Woo API expects integer ID for categories usually.
			// Our ChannelCategoryID is string.
		}
	}

	// 5. Send Request
	// Check if we are creating or updating
	var method, urlStr string
	if product.ProductWoo.WooProductID != nil && *product.ProductWoo.WooProductID > 0 {
		// Update
		method = "PUT"
		urlStr = fmt.Sprintf("%s/wp-json/wc/v3/products/%d", strings.TrimRight(store.SiteURL, "/"), *product.ProductWoo.WooProductID)
	} else {
		// Create
		method = "POST"
		urlStr = fmt.Sprintf("%s/wp-json/wc/v3/products", strings.TrimRight(store.SiteURL, "/"))
	}

	jsonBody, _ := json.Marshal(payload)
	req, _ := http.NewRequest(method, urlStr, bytes.NewBuffer(jsonBody))
	req.SetBasicAuth(ck, cs)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	if !store.VerifySSL {
		client.Transport = &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("woo api error (%d): %s", resp.StatusCode, string(bodyBytes))
	}

	// 6. Parse Response and Update DB
	var wooResp map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &wooResp); err != nil {
		return fmt.Errorf("failed to parse woo response: %w", err)
	}

	idFloat, ok := wooResp["id"].(float64)
	if !ok {
		return fmt.Errorf("no id in woo response")
	}
	wooID := int64(idFloat)
	status, _ := wooResp["status"].(string)
	// permalink, _ := wooResp["permalink"].(string)

	// Update ProductWoo
	// We need to ensure ProductWoo record exists (it should from CreateProduct handler)
	// But if not, create it.
	if product.ProductWoo.ID == 0 {
		product.ProductWoo = models.ProductWoo{
			ProductID: product.ID,
		}
	}

	product.ProductWoo.WooProductID = &wooID
	product.ProductWoo.Status = status
	// We might want to store permalink too if we had a field for it.

	now := time.Now()
	product.ProductWoo.LastPublishedAt = &now

	if err := s.db.Save(&product.ProductWoo).Error; err != nil {
		return fmt.Errorf("failed to update product woo record: %w", err)
	}

	// Also update ProductChannel LastPublishedAt
	pc.LastPublishedAt = &now
	s.db.Save(&pc)

	// Log success
	// (Optional: create ChannelPublishLog)

	return nil
}
