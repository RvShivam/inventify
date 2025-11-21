package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/RvShivam/inventify/internal/models"
)

// CreateProduct handles the creation of a new product with optional channel configs and images.
// Expects Multipart form:
// - "data": JSON string of createProductReq
// - "images": List of files
func CreateProduct(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Parse Multipart Form
		// Limit upload size to 32MB
		if err := c.Request.ParseMultipartForm(32 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse multipart form"})
			return
		}

		// 2. Extract JSON data
		jsonData := c.Request.FormValue("data")
		if jsonData == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'data' field"})
			return
		}

		var req createProductReq
		if err := json.Unmarshal([]byte(jsonData), &req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON data: %v", err)})
			return
		}

		// 3. Handle Image Uploads
		form, _ := c.MultipartForm()
		files := form.File["images"]
		var savedImagePaths []string

		// Ensure uploads directory exists
		uploadDir := "uploads"
		if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
			os.Mkdir(uploadDir, 0755)
		}

		for _, file := range files {
			// Generate unique filename
			ext := filepath.Ext(file.Filename)
			filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
			path := filepath.Join(uploadDir, filename)

			// Save file
			if err := c.SaveUploadedFile(file, path); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to save image: %v", err)})
				return
			}
			// In a real app, you'd upload to S3/Cloudinary and get a URL.
			// For now, we store the relative path.
			// Assuming the server serves /uploads route.
			savedImagePaths = append(savedImagePaths, "/"+path)
		}

		// 4. Database Transaction
		tx := db.Begin()
		if tx.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		// Find or Create Category
		var categoryID *uint
		if req.CategoryName != "" {
			var cat models.Category
			// Try to find by name
			if err := tx.Where("name = ?", req.CategoryName).First(&cat).Error; err == nil {
				categoryID = &cat.ID
			} else if err == gorm.ErrRecordNotFound {
				// Create if not exists (optional, or return error)
				cat = models.Category{Name: req.CategoryName}
				if err := tx.Create(&cat).Error; err != nil {
					tx.Rollback()
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create category"})
					return
				}
				categoryID = &cat.ID
			} else {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error finding category"})
				return
			}
		}

		// Create Product
		product := models.Product{
			OrganizationID: 1, // Hardcoded for now, or get from auth context
			Name:           req.Name,
			ShortDescription: req.ShortDescription,
			Description:      req.Description,
			SKU:              req.SKU,
			Brand:            req.Brand,
			HSNCode:          req.HSNCode,
			CountryOfOrigin:  req.CountryOfOrigin,
			LocalCategoryID:  categoryID,
			RegularPrice:     req.RegularPrice,
			SalePrice:        req.SalePrice,
			StockQuantity:    req.StockQuantity,
			ManageStock:      true,
			WeightKg:         req.WeightKg,
			LengthCm:         req.LengthCm,
			WidthCm:          req.WidthCm,
			HeightCm:         req.HeightCm,
		}

		if err := tx.Create(&product).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create product: %v", err)})
			return
		}

		// Create Images
		for i, src := range savedImagePaths {
			img := models.ProductImage{
				ProductID: product.ID,
				Src:       src,
				Position:  i,
				IsPrimary: i == 0,
			}
			if err := tx.Create(&img).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save product images"})
				return
			}
		}

		// Handle WooCommerce
		if req.Woo != nil && req.Woo.Enabled {
			woo := models.ProductWoo{
				ProductID:          product.ID,
				Status:             "publish", // Default to publish if enabled
				Type:               "simple",
				CatalogVisibility:  req.Woo.CatalogVisibility,
				CustomPriceEnabled: req.Woo.CustomPrice != nil,
				CustomPriceValue:   req.Woo.CustomPrice,
			}
			if err := tx.Create(&woo).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save WooCommerce settings"})
				return
			}
			
			// Also add to ProductChannels
			// Find Woo Channel ID (assuming it exists)
			var wooChannel models.Channel
			if err := tx.Where("name = ? AND organization_id = ?", "woocommerce", 1).First(&wooChannel).Error; err == nil {
				pc := models.ProductChannel{
					ProductID: product.ID,
					ChannelID: wooChannel.ID,
					IsEnabled: true,
				}
				tx.Create(&pc)
			}
		}

		// Handle ONDC
		if req.ONDC != nil && req.ONDC.Enabled {
			ondc := models.ProductONDC{
				ProductID:       product.ID,
				FulfillmentType: req.ONDC.FulfillmentType,
				TimeToShip:      req.ONDC.TimeToShip,
				CityCode:        req.ONDC.CityCode,
				Returnable:      req.ONDC.Returnable,
				Cancellable:     req.ONDC.Cancellable,
				Warranty:        req.ONDC.Warranty,
			}
			if err := tx.Create(&ondc).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save ONDC settings"})
				return
			}

			// Also add to ProductChannels
			var ondcChannel models.Channel
			if err := tx.Where("name = ? AND organization_id = ?", "ondc", 1).First(&ondcChannel).Error; err == nil {
				pc := models.ProductChannel{
					ProductID: product.ID,
					ChannelID: ondcChannel.ID,
					IsEnabled: true,
				}
				tx.Create(&pc)
			}
		}

		tx.Commit()
		c.JSON(http.StatusCreated, gin.H{"message": "Product created successfully", "id": product.ID})
	}
}

type createProductReq struct {
	Name             string   `json:"name"`
	ShortDescription string   `json:"short_description"`
	Description      string   `json:"description"`
	SKU              string   `json:"sku"`
	Brand            string   `json:"brand"`
	HSNCode          string   `json:"hsn_code"`
	CountryOfOrigin  string   `json:"country_of_origin"`
	CategoryName     string   `json:"category_name"`
	
	RegularPrice     float64  `json:"regular_price"`
	SalePrice        *float64 `json:"sale_price"`
	StockQuantity    int      `json:"stock_quantity"`
	
	WeightKg         *float64 `json:"weight_kg"`
	LengthCm         *float64 `json:"length_cm"`
	WidthCm          *float64 `json:"width_cm"`
	HeightCm         *float64 `json:"height_cm"`

	Woo  *wooSettings  `json:"woo"`
	ONDC *ondcSettings `json:"ondc"`
}

type wooSettings struct {
	Enabled           bool     `json:"enabled"`
	CustomPrice       *float64 `json:"custom_price"`
	CatalogVisibility string   `json:"catalog_visibility"`
}

type ondcSettings struct {
	Enabled         bool     `json:"enabled"`
	Returnable      bool     `json:"returnable"`
	Cancellable     bool     `json:"cancellable"`
	CustomPrice     *float64 `json:"custom_price"`
	FulfillmentType string   `json:"fulfillment_type"`
	TimeToShip      string   `json:"time_to_ship"`
	CityCode        string   `json:"city_code"`
	Warranty        string   `json:"warranty"`
}
