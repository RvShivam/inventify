package services

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/RvShivam/inventify/internal/models"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type OrderService struct {
	db *gorm.DB
}

func NewOrderService(db *gorm.DB) *OrderService {
	return &OrderService{db: db}
}

// CreateOrUpdateOrderFromWoo processes a WooCommerce webhook payload
func (s *OrderService) CreateOrUpdateOrderFromWoo(organizationID uint, payload map[string]interface{}) error {
	// 1. Extract Core Fields
	idVal, _ := payload["id"].(float64) // JSON numbers are float64
	externalID := fmt.Sprintf("%.0f", idVal)
	status, _ := payload["status"].(string)
	currency, _ := payload["currency"].(string)
	totalStr, _ := payload["total"].(string)
	total, _ := strconv.ParseFloat(totalStr, 64)

	// Customer info
	billing, _ := payload["billing"].(map[string]interface{})
	firstName, _ := billing["first_name"].(string)
	lastName, _ := billing["last_name"].(string)
	email, _ := billing["email"].(string)
	customerName := fmt.Sprintf("%s %s", firstName, lastName)

	// 2. Prepare JSONB fields
	billingJSON, _ := json.Marshal(payload["billing"])
	shippingJSON, _ := json.Marshal(payload["shipping"])
	lineItemsJSON, _ := json.Marshal(payload["line_items"])
	rawJSON, _ := json.Marshal(payload)

	// 3. Upsert Order
	var order models.Order
	err := s.db.Where("external_id = ? AND source = ?", externalID, "woocommerce").First(&order).Error

	if err == nil {
		// Update existing
		order.Status = status
		order.Total = total
		order.Currency = currency
		order.CustomerName = customerName
		order.CustomerEmail = email
		order.BillingAddress = datatypes.JSON(billingJSON)
		order.ShippingAddress = datatypes.JSON(shippingJSON)
		order.LineItems = datatypes.JSON(lineItemsJSON)
		order.RawData = datatypes.JSON(rawJSON)
		return s.db.Save(&order).Error
	} else if err == gorm.ErrRecordNotFound {
		// Create new
		newOrder := models.Order{
			OrganizationID:  organizationID,
			ExternalID:      externalID,
			Source:          "woocommerce",
			Status:          status,
			Currency:        currency,
			Total:           total,
			CustomerName:    customerName,
			CustomerEmail:   email,
			BillingAddress:  datatypes.JSON(billingJSON),
			ShippingAddress: datatypes.JSON(shippingJSON),
			LineItems:       datatypes.JSON(lineItemsJSON),
			RawData:         datatypes.JSON(rawJSON),
		}

		if err := s.db.Create(&newOrder).Error; err != nil {
			return err
		}

		// Deduct Stock for new orders
		fmt.Println("📦 New order created, processing stock deduction...")
		// We iterate over the raw line_items payload
		if items, ok := payload["line_items"].([]interface{}); ok {
			for _, item := range items {
				itemMap, ok := item.(map[string]interface{})
				if !ok {
					continue
				}

				// Get Woo Product ID
				wooIDFloat, _ := itemMap["product_id"].(float64)
				wooID := int64(wooIDFloat)

				// Get Quantity
				qtyFloat, _ := itemMap["quantity"].(float64)
				qty := int(qtyFloat)

				fmt.Printf("   - Item: WooID=%d, Qty=%d\n", wooID, qty)

				if qty <= 0 {
					continue
				}

				// Find local product via ProductWoo
				var productWoo models.ProductWoo
				if err := s.db.Where("woo_product_id = ?", wooID).First(&productWoo).Error; err != nil {
					fmt.Printf("   ❌ Local product not found for WooID %d: %v\n", wooID, err)
					continue
				}
				fmt.Printf("   ✅ Found local ProductID: %d\n", productWoo.ProductID)

				// Update Product Stock
				// We use a transaction or just direct update.
				// For simplicity and speed in this sync handler:
				if err := s.db.Model(&models.Product{}).Where("id = ?", productWoo.ProductID).
					UpdateColumn("stock_quantity", gorm.Expr("stock_quantity - ?", qty)).Error; err != nil {
					fmt.Printf("   ❌ Failed to update stock for product %d: %v\n", productWoo.ProductID, err)
				} else {
					fmt.Printf("   ✅ Stock deducted for product %d\n", productWoo.ProductID)
				}

				// Record Movement
				movement := models.InventoryMovement{
					ProductID: productWoo.ProductID,
					ChangeQty: -qty,
					Reason:    "order_sync_woo",
					Ref:       fmt.Sprintf("woo_order_%s", externalID),
				}
				s.db.Create(&movement)
			}
		} else {
			fmt.Println("   ❌ Failed to parse line_items")
		}

		return nil
	}

	return err
}
