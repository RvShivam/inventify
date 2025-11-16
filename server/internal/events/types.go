package events

import "time"

// Exchange & routing keys
const (
	ExchangeName = "inventify.events"
	ExchangeType = "topic"

	// routing keys
	RoutingKeyWooStoreConnected  = "woo.store.connected"
	RoutingKeyWooWebhookReceived = "woo.webhook.received"
	// add more routing keys as needed...
)

// BaseEvent is a small envelope shared by all events.
type BaseEvent struct {
	Event     string    `json:"event"`
	Version   int       `json:"version"`
	Timestamp time.Time `json:"timestamp"`
}

// WooStoreConnectedEvent fired when a Woo store is successfully connected.
type WooStoreConnectedEvent struct {
	BaseEvent
	StoreID        uint   `json:"store_id"`
	OrganizationID uint   `json:"organization_id"`
	SiteURL        string `json:"site_url"`
}
