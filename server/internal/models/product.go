package models

import (
	"time"

	"gorm.io/gorm"
)

// Product defines the master inventory item template.
type Product struct {
	gorm.Model
	OrganizationID      uint   `gorm:"not null;index"`
	Name                string `gorm:"not null;index"`
	Description         string `gorm:"type:text"`
	Category            string `gorm:"not null;index"`
	Brand               string `gorm:"not null;index"`
	HSNCode             string `gorm:"size:8;index"`
	CountryOfOrigin     string `gorm:"size:2"`
	NetQuantity         string
	NetQuantityUnit     string
	ManufacturerName    string `gorm:"size:20"`
	ManufacturerAddress string
	PackerName          string `gorm:"size:20"`
	PackerAddress       string
	IsPublished         bool             `gorm:"default:false"`
	Variants            []ProductVariant `gorm:"constraint:,OnDelete:CASCADE;"`
	Images              []ProductImage   `gorm:"constraint:,OnDelete:CASCADE;"`
}

type ProductImage struct {
	gorm.Model
	ProductID uint   `gorm:"not null;index"`
	ImageURL  string `gorm:"not null"`
	AltText   string
	Position  int
}

type ProductVariant struct {
	gorm.Model
	ProductID       uint    `gorm:"not null;index"`
	SKU             string  `gorm:"unique;not null;index"`
	Price           float64 `gorm:"not null"`
	CompareAtPrice  float64
	Barcode         string
	Quantity        uint `gorm:"not null;default:0"`
	Weight          float64
	Length          float64
	Width           float64
	Height          float64
	Attributes      VariantAttributes `gorm:"type:jsonb;serializer:json"`
	ChannelProducts []ChannelProduct
	Locations       []VariantLocation
}

type VariantAttributes struct {
	Size     string            `json:"size,omitempty"`
	Color    string            `json:"color,omitempty"`
	Material string            `json:"material,omitempty"`
	Custom   map[string]string `json:"custom,omitempty"`
}

type Channel struct {
	gorm.Model
	OrganizationID uint   `gorm:"not null;index"`
	Name           string `gorm:"not null"`
	StoreURL       string
	APIKey         string `gorm:"not null"`
	APISecret      string
	IsActive       bool `gorm:"default:true"`
	Locations      []ChannelLocation
}

type ChannelMetadata struct {
	TaxStatus        string   `json:"tax_status,omitempty"`
	TaxClass         string   `json:"tax_class,omitempty"`
	ShippingClass    string   `json:"shipping_class,omitempty"`
	ProductType      string   `json:"product_type,omitempty"`
	Tags             []string `json:"tags,omitempty"`
	Collections      []string `json:"collections,omitempty"`
	WarrantyType     string   `json:"warranty_type,omitempty"`
	WarrantyDuration string   `json:"warranty_duration,omitempty"`
	LeadTime         int      `json:"lead_time,omitempty"`
}

type ChannelProduct struct {
	gorm.Model
	ProductVariantID    uint   `gorm:"not null;index;uniqueIndex:idx_channel_variant"`
	ChannelID           uint   `gorm:"not null;index;uniqueIndex:idx_channel_variant"`
	ExternalProductID   string `gorm:"not null;index"`
	ExternalVariantID   string `gorm:"index"`
	ExternalInventoryID string
	Handle              string
	Price               float64
	Published           bool
	SyncStatus          string `gorm:"default:'pending';index"`
	LastSyncedAt        *time.Time
	SyncError           string          `gorm:"type:text"`
	Metadata            ChannelMetadata `gorm:"type:jsonb;serializer:json"`
}

type Location struct {
	gorm.Model
	OrganizationID uint   `gorm:"not null;index"`
	Name           string `gorm:"not null"`
	Address        string `gorm:"type:text;not null"`
	City           string
	State          string
	Pincode        string
	Country        string `gorm:"default:'IN'"`
	IsActive       bool   `gorm:"default:true"`
	IsDefault      bool   `gorm:"default:false"`
}

type VariantLocation struct {
	gorm.Model
	ProductVariantID uint `gorm:"not null;index;uniqueIndex:idx_variant_location"`
	LocationID       uint `gorm:"not null;index;uniqueIndex:idx_variant_location"`
	Quantity         uint `gorm:"not null;default:0"`
}

type ChannelLocation struct {
	gorm.Model
	ChannelID  uint `gorm:"not null;index;uniqueIndex:idx_channel_location"`
	LocationID uint `gorm:"not null;index;uniqueIndex:idx_channel_location"`
	IsEnabled  bool `gorm:"default:true"`
}

// Orders and Webhooks Related Models
type Order struct {
	gorm.Model
	OrganizationID  uint        `gorm:"not null;index"`
	ChannelID       uint        `gorm:"not null;index"`
	ExternalOrderID string      `gorm:"not null;index;uniqueIndex:idx_channel_order"`
	OrderStatus     string      `gorm:"not null;default:'pending';index"`
	OrderTotal      float64     `gorm:"not null"`
	Currency        string      `gorm:"size:3;default:'INR'"`
	CustomerEmail   string      `gorm:"index"`
	OrderDetails    string      `gorm:"type:jsonb"`
	OrderTime       time.Time   `gorm:"not null;index"`
	OrderItems      []OrderItem `gorm:"constraint:OnDelete:CASCADE"`
}

// OrderItem stores line items per order.
type OrderItem struct {
	gorm.Model
	OrderID          uint    `gorm:"not null;index"`
	ProductVariantID uint    `gorm:"not null;index"`
	Quantity         int     `gorm:"not null"`
	Price            float64 `gorm:"not null"`
	SKU              string
}

// --- Sync, Webhooks, and Audit ---
type SyncQueue struct {
	gorm.Model
	ProductVariantID uint       `gorm:"not null;index"`
	ChannelID        uint       `gorm:"not null;index"`
	Action           string     `gorm:"not null"`
	Payload          string     `gorm:"type:jsonb"`
	Status           string     `gorm:"default:'pending';index"`
	RetryCount       int        `gorm:"default:0"`
	NextRetryAt      *time.Time `gorm:"index"`
	ErrorMessage     string     `gorm:"type:text"`
	CompletedAt      *time.Time
}

type WebhookEvent struct {
	gorm.Model
	ChannelID       uint   `gorm:"not null;index"`
	ExternalEventID string `gorm:"unique;not null"`
	EventType       string `gorm:"not null;index"`
	Payload         string `gorm:"type:jsonb"`
	ProcessedAt     *time.Time
	Status          string `gorm:"default:'pending'"`
	ErrorMessage    string `gorm:"type:text"`
}

// InventoryLog is a ledger of every stock change.
type InventoryLog struct {
	gorm.Model
	ProductVariantID uint `gorm:"not null;index"`
	LocationID       uint `gorm:"index"`
	OrganizationID   uint `gorm:"not null;index"`
	ChangeAmount     int
	Reason           string
	OrderID          uint `gorm:"index"`
}
