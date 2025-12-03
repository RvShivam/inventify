package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"

	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func generateNewReferralCode(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// GetOrganization returns the current user's organization details
func GetOrganization(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get orgID from context (set by RequireAuth middleware)
		orgIDVal, exists := c.Get("org_Id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Organization ID not found in context"})
			return
		}
		orgID := orgIDVal.(uint)

		var org models.Organization
		if err := db.Preload("Users").First(&org, orgID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Organization not found"})
			return
		}

		// Count members
		memberCount := int64(len(org.Users))

		c.JSON(http.StatusOK, gin.H{
			"id":           org.ID,
			"name":         org.Name,
			"referralCode": org.ReferralCode,
			"memberCount":  memberCount,
		})
	}
}

// RegenerateReferralCode updates the organization's referral code (Admin only)
func RegenerateReferralCode(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get orgID and roleID from context
		orgIDVal, exists := c.Get("org_Id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Organization ID not found in context"})
			return
		}
		orgID := orgIDVal.(uint)

		userIDVal, exists := c.Get("user_Id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
			return
		}
		userID := userIDVal.(uint)

		var member models.OrganizationMember
		if err := db.Where("organization_id = ? AND user_id = ?", orgID, userID).First(&member).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "User not member of organization"})
			return
		}

		if member.RoleID != 1 { // Assuming 1 is Admin
			c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can regenerate referral codes"})
			return
		}

		newCode, err := generateNewReferralCode(4) // 8 chars
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate code"})
			return
		}

		if err := db.Model(&models.Organization{}).Where("id = ?", orgID).Update("referral_code", newCode).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update referral code"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"referralCode": newCode,
			"message":      "Referral code updated successfully",
		})
	}
}
