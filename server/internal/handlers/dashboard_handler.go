package handlers

import (
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"net/http"
)

// DashboardResponse defines the structure of the data sent to the frontend
type DashboardResponse struct {
	Metrics      DashboardMetrics `json:"metrics"`
	RecentOrders []RecentOrder    `json:"recentOrders"`
}

type DashboardMetrics struct {
	TotalSales    float64 `json:"totalSales"`
	TotalOrders   int64   `json:"totalOrders"`
	ProductCount  int64   `json:"productCount"`
	LowStockCount int64   `json:"lowStockCount"`
}

type RecentOrder struct {
	Title    string `json:"title"`
	Subtitle string `json:"subtitle"`
	Amount   string `json:"amount"`
}

// GetDashboard fetches the data for the main dashboard
func GetDashboard(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the user ID from the middleware
		userID, _ := c.Get("userId")

		// Find the organization this user belongs to
		var member models.OrganizationMember
		if err := db.Where("user_id = ?", userID).First(&member).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User organization not found"})
			return
		}
		orgID := member.OrganizationID

		// --- Fetch data from the database ---
		var productCount int64
		db.Model(&models.Product{}).Where("organization_id = ?", orgID).Count(&productCount)

		var lowStockCount int64
		db.Model(&models.Product{}).Where("organization_id = ? AND quantity < ?", orgID, 10).Count(&lowStockCount)

		// --- Use DUMMY data for now (since we don't have an orders table yet) ---
		metrics := DashboardMetrics{
			TotalSales:    1250.00,
			TotalOrders:   82,
			ProductCount:  productCount,
			LowStockCount: lowStockCount,
		}

		recentOrders := []RecentOrder{
			{Title: "Order #1082 - Handmade Scarf", Subtitle: "Shopify, 2m ago", Amount: "$25.00"},
			{Title: "Order #1081 - Clay Vase", Subtitle: "WooCommerce, 1h ago", Amount: "$40.00"},
			{Title: "Order #1080 - Scented Candle", Subtitle: "Amazon, 3h ago", Amount: "$15.50"},
		}

		response := DashboardResponse{
			Metrics:      metrics,
			RecentOrders: recentOrders,
		}

		c.JSON(http.StatusOK, response)
	}
}
