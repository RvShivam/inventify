package handlers

import (
	"net/http"
	"strconv"

	"github.com/RvShivam/inventify/internal/services"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SyncProductToWooInternal handles the internal request to sync a product to WooCommerce.
// This is called by the worker.
func SyncProductToWooInternal(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
			return
		}

		productService := services.NewProductService(db)
		if err := productService.SyncProductToWoo(uint(id)); err != nil {
			// Return 500 so worker can retry
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "synced"})
	}
}
