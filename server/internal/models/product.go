package models

import (
	"time"

	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// ─────────────────────────────────────────────────────────────
//						CATEGORIES
// ─────────────────────────────────────────────────────────────

// Category (Global predefined list)
type Category struct {
	gorm.Model
	Name        string `gorm:"not null;index"` // human name (e.g., "Electronics")
	Description string `gorm:"type:text"`
}

// CategoryMapping maps a global Category to a channel-specific category id.
type CategoryMapping struct {
	gorm.Model
	CategoryID        uint   `gorm:"index;not null"`         // FK → Category.ID
	Channel           string `gorm:"size:50;index;not null"` // 'woocommerce', 'ondc'
	ChannelCategoryID string `gorm:"not null"`               // ID from Woo or ONDC
	IsDefault         bool   `gorm:"default:false"`
}

// ─────────────────────────────────────────────────────────────
// 						PRODUCT CORE
// ─────────────────────────────────────────────────────────────

type Product struct {
	gorm.Model

	OrganizationID uint   `gorm:"index;not null"`
	Name           string `gorm:"not null;index"`
	//Slug           string `gorm:"index"`

	ShortDescription string `gorm:"type:text"`
	Description      string `gorm:"type:text"`

	SKU string `gorm:"index"`
	//Barcode string
	Brand string

	LocalCategoryID *uint     `gorm:"index;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	LocalCategory   *Category `gorm:"foreignKey:LocalCategoryID"`

	RegularPrice float64  `gorm:"type:decimal(10,2);default:0;not null"`
	SalePrice    *float64 `gorm:"type:decimal(10,2)"`

	// Stock
	ManageStock   bool `gorm:"default:true"`
	StockQuantity int  `gorm:"default:0;not null"`

	// Weight & Dimensions
	WeightKg *float64
	LengthCm *float64
	WidthCm  *float64
	HeightCm *float64

	HSNCode         string
	CountryOfOrigin string `gorm:"size:2;default:IN"`

	IsFeatured     bool `gorm:"default:false"`
	ReviewsAllowed bool `gorm:"default:true"`

	Images            []ProductImage
	ProductWoo        ProductWoo
	ProductONDC       ProductONDC
	ChannelOverrides  []ProductChannelOverride
	ProductChannels   []ProductChannel
	LocationStock     []ProductLocationStock
	PublishLogs       []ChannelPublishLog
	InventoryMovement []InventoryMovement
}

type ProductImage struct {
	gorm.Model
	ProductID uint   `gorm:"index;not null;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;"`
	Src       string `gorm:"not null"`
	Alt       string
	Position  int  `gorm:"default:0"`
	IsPrimary bool `gorm:"default:false"`
}

//
// ─────────────────────────────────────────────────────────────
// CHANNELS (Normalized, every org has channels)
// ─────────────────────────────────────────────────────────────
//

type Channel struct {
	gorm.Model
	OrganizationID uint           `gorm:"index;not null"`
	Name           string         `gorm:"size:50;not null"` // 'woocommerce', 'ondc'
	Type           string         `gorm:"size:50;not null"` // 'ecommerce', 'ondc'
	IsActive       bool           `gorm:"default:true"`
	Config         datatypes.JSON `gorm:"type:jsonb"`
}

// Pivot table to track product-channel activation
type ProductChannel struct {
	gorm.Model
	ProductID       uint `gorm:"index;not null;uniqueIndex:ux_product_channel"`
	ChannelID       uint `gorm:"index;not null;uniqueIndex:ux_product_channel"`
	IsEnabled       bool `gorm:"default:false"`
	LastPublishedAt *time.Time
}

//
// ─────────────────────────────────────────────────────────────
// WOOCOMMERCE CONNECTION TABLES (Normalized)
// ─────────────────────────────────────────────────────────────
//

type WooStore struct {
	gorm.Model

	OrganizationID          uint   `gorm:"index;not null"`
	Name                    string `gorm:"not null"` // label
	SiteURL                 string `gorm:"not null"`
	ConsumerKeyEncrypted    string `gorm:"not null"`
	ConsumerSecretEncrypted string `gorm:"not null"`
	WebhookSecretEncrypted  string

	VerifySSL bool `gorm:"default:true"`
	IsActive  bool `gorm:"default:true"`
	IsDefault bool `gorm:"default:false"`

	LastSyncedAt *time.Time
}

type WooStoreWebhook struct {
	gorm.Model
	WooStoreID      uint   `gorm:"index;not null"`
	WebhookID       string // Woo ID
	Topic           string `gorm:"not null"`
	DeliveryURL     string `gorm:"not null"`
	SecretEncrypted string
	Active          bool `gorm:"default:true"`
	LastDelivered   *time.Time
}

//
// ─────────────────────────────────────────────────────────────
// PRODUCT → WOO OVERRIDES (Normalized 1-1 table)
// ─────────────────────────────────────────────────────────────
//

type ProductWoo struct {
	gorm.Model

	ProductID uint `gorm:"uniqueIndex;not null"`

	WooProductID      *int64
	WooCategoryID     string
	Status            string `gorm:"size:20;default:'draft'"`
	Type              string `gorm:"size:20;default:'simple'"`
	CatalogVisibility string `gorm:"size:20;default:'visible'"`
	//SoldIndividually   bool   `gorm:"default:false"`
	CustomPriceEnabled bool `gorm:"default:false"`
	CustomPriceValue   *float64
	LastPublishedAt    *time.Time
}

//
// ─────────────────────────────────────────────────────────────
// PRODUCT → ONDC OVERRIDES (Normalized 1-1 table)
// ─────────────────────────────────────────────────────────────
//

type ProductONDC struct {
	gorm.Model

	ProductID uint `gorm:"uniqueIndex;not null"`

	ONDCItemID     string
	ONDCCategoryID string // mapped category id

	FulfillmentType string `gorm:"size:20;not null"` // delivery/pickup/both
	TimeToShip      string // ISO duration (P2D)
	CityCode        string

	Returnable  bool `gorm:"default:true"`
	Cancellable bool `gorm:"default:true"`
	Warranty    string

	LastPublishedAt *time.Time
}

//
// ─────────────────────────────────────────────────────────────
// OVERRIDE JSON (for future channels/extensibility)
// ─────────────────────────────────────────────────────────────
//

type ProductChannelOverride struct {
	gorm.Model
	ProductID uint           `gorm:"index;not null"`
	Channel   string         `gorm:"size:50;not null"`
	Data      datatypes.JSON `gorm:"type:jsonb"`
}

//
// ─────────────────────────────────────────────────────────────
// SELLER LOCATIONS (ONDC)
// ─────────────────────────────────────────────────────────────
//

type SellerLocation struct {
	gorm.Model

	OrganizationID uint `gorm:"index;not null"`
	Name           string
	AddressLine1   string
	AddressLine2   string
	City           string
	State          string
	Country        string `gorm:"size:2;default:IN"`
	AreaCode       string
	GPS            string
	CityCode       string
	Phone          string
	IsActive       bool `gorm:"default:true"`
}

type ProductLocationStock struct {
	gorm.Model
	ProductID  uint `gorm:"index;not null"`
	LocationID uint `gorm:"index;not null"`
	StockQty   int  `gorm:"default:0"`
	LastSynced *time.Time
}

//
// ─────────────────────────────────────────────────────────────
// INVENTORY RESERVATION + MOVEMENT (optional normalized)
// ─────────────────────────────────────────────────────────────
//

type InventoryReservation struct {
	ID          string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProductID   uint      `gorm:"index;not null"`
	Source      string    `gorm:"size:64;not null"`
	ContextID   string    `gorm:"not null;index"` // for idempotency
	ReservedQty int       `gorm:"not null"`
	Status      string    `gorm:"size:20;default:'reserved'"`
	CreatedAt   time.Time `gorm:"autoCreateTime"`
	ExpiresAt   *time.Time
	Metadata    datatypes.JSON `gorm:"type:jsonb"`
}

type InventoryMovement struct {
	ID        string `gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	ProductID uint   `gorm:"index;not null"`
	ChangeQty int    `gorm:"not null"`
	Reason    string
	Ref       string
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

//
// ─────────────────────────────────────────────────────────────
// CHANNEL PUBLISH LOGS (Normalized)
// ─────────────────────────────────────────────────────────────
//

type ChannelPublishLog struct {
	gorm.Model
	ProductID         uint   `gorm:"index;not null"`
	Channel           string `gorm:"size:50;not null"`
	Success           bool   `gorm:"default:false"`
	ChannelResourceID string
	RequestPayload    datatypes.JSON `gorm:"type:jsonb"`
	ResponsePayload   datatypes.JSON `gorm:"type:jsonb"`
	ErrorMessage      string
	AttemptAt         time.Time `gorm:"autoCreateTime"`
}
