package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// Order represents a unified order structure for all channels
type Order struct {
	ID             uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	OrganizationID uint      `gorm:"index;not null" json:"organization_id"`
	ExternalID     string    `gorm:"index" json:"external_id"` // e.g., WooCommerce Order ID
	Source         string    `gorm:"index" json:"source"`      // e.g., "woocommerce", "ondc"
	Status         string    `gorm:"index" json:"status"`      // e.g., "processing", "completed"
	Currency       string    `json:"currency"`
	Total          float64   `json:"total"`
	CustomerName   string    `json:"customer_name"`
	CustomerEmail  string    `json:"customer_email"`

	// JSONB fields for flexible data
	BillingAddress  datatypes.JSON `gorm:"type:jsonb" json:"billing_address"`
	ShippingAddress datatypes.JSON `gorm:"type:jsonb" json:"shipping_address"`
	LineItems       datatypes.JSON `gorm:"type:jsonb" json:"line_items"`
	RawData         datatypes.JSON `gorm:"type:jsonb" json:"raw_data"` // Full original payload

	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Helper structs for JSONB fields (to be used when unmarshalling)

type OrderAddress struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Company   string `json:"company"`
	Address1  string `json:"address_1"`
	Address2  string `json:"address_2"`
	City      string `json:"city"`
	State     string `json:"state"`
	Postcode  string `json:"postcode"`
	Country   string `json:"country"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
}

type OrderLineItem struct {
	ID          int64   `json:"id"`
	Name        string  `json:"name"`
	ProductID   int64   `json:"product_id"`
	VariationID int64   `json:"variation_id"`
	Quantity    int     `json:"quantity"`
	TaxClass    string  `json:"tax_class"`
	Subtotal    string  `json:"subtotal"`
	SubtotalTax string  `json:"subtotal_tax"`
	Total       string  `json:"total"`
	TotalTax    string  `json:"total_tax"`
	SKU         string  `json:"sku"`
	Price       float64 `json:"price"`
}
