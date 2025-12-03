package events

import (
	"encoding/json"
	"log"

	"github.com/RvShivam/inventify/internal/models"
	"github.com/RvShivam/inventify/internal/services"
	"gorm.io/gorm"
)

// StartOrderConsumer starts listening for order-related events
func StartOrderConsumer(db *gorm.DB) {
	orderService := services.NewOrderService(db)

	handler := func(body []byte) error {
		var event map[string]interface{}
		if err := json.Unmarshal(body, &event); err != nil {
			log.Printf("❌ Error decoding event: %v", err)
			return nil // Return nil to Ack (poison message)
		}

		// Check if it's an order topic
		topic, _ := event["topic"].(string)
		if topic != "order.created" && topic != "order.updated" {
			// Ignore other topics (e.g., product.updated)
			return nil
		}

		payload, ok := event["payload"].(map[string]interface{})
		if !ok {
			log.Printf("❌ Invalid payload format")
			return nil
		}

		// Extract woo_store_webhook info to find OrganizationID
		wooWebhookInfo, ok := event["woo_store_webhook"].(map[string]interface{})
		if !ok {
			log.Printf("❌ Missing woo_store_webhook info")
			return nil
		}

		// We need to find the OrganizationID.
		// The event has woo_store_webhook.id (which is the DB ID of WooStoreWebhook).
		// From WooStoreWebhook we can get WooStoreID, and from WooStore we get OrganizationID.

		webhookDBIDFloat, _ := wooWebhookInfo["id"].(float64)
		webhookDBID := uint(webhookDBIDFloat)

		var wsWebhook models.WooStoreWebhook
		if err := db.First(&wsWebhook, webhookDBID).Error; err != nil {
			log.Printf("❌ Could not find WooStoreWebhook %d: %v", webhookDBID, err)
			return nil // Maybe retry?
		}

		var wooStore models.WooStore
		if err := db.First(&wooStore, wsWebhook.WooStoreID).Error; err != nil {
			log.Printf("❌ Could not find WooStore %d: %v", wsWebhook.WooStoreID, err)
			return nil
		}

		log.Printf("📦 Processing Order Webhook: %s (OrgID: %d)", topic, wooStore.OrganizationID)

		if err := orderService.CreateOrUpdateOrderFromWoo(wooStore.OrganizationID, payload); err != nil {
			log.Printf("❌ Error processing order: %v", err)
			return err // Return error to Nack/Retry
		}

		log.Println("✅ Order processed successfully")
		return nil
	}

	// Register consumer
	// Queue: worker.orders.woo
	// Binding: woo.webhook.received
	err := Consume("worker.orders.woo", "woo.webhook.received", handler)
	if err != nil {
		log.Printf("❌ Failed to register order consumer: %v", err)
	} else {
		log.Println("🎧 Order Consumer registered for 'woo.webhook.received'")
	}
}
