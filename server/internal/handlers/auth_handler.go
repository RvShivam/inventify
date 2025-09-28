package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"net/http"
	"os"
	"time"
)

func generateReferralCode(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// SignupRequest binds the incoming JSON from the signup form
type SignupRequest struct {
	Name         string
	Email        string
	Password     string
	ShopName     string
	ReferralCode string
}

func Signup(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req SignupRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
			return
		}

		newUser := models.User{
			Name:     req.Name,
			Email:    req.Email,
			Password: string(hashedPassword),
		}

		err = db.Transaction(func(tx *gorm.DB) error {
			if err := tx.Create(&newUser).Error; err != nil {
				return err
			}

			if req.ShopName != "" {
				// Use the new function to generate a random code
				newReferralCode, err := generateReferralCode(4) // Creates an 8-character string
				if err != nil {
					return err
				}

				newOrg := models.Organization{
					Name:         req.ShopName,
					OwnerID:      newUser.ID,
					ReferralCode: newReferralCode,
				}
				if err := tx.Create(&newOrg).Error; err != nil {
					return err
				}

				member := models.OrganizationMember{UserID: newUser.ID, OrganizationID: newOrg.ID, RoleID: 1}
				if err := tx.Create(&member).Error; err != nil {
					return err
				}
			} else if req.ReferralCode != "" {
				var org models.Organization
				if err := tx.Where("referral_code = ?", req.ReferralCode).First(&org).Error; err != nil {
					return err
				}

				member := models.OrganizationMember{UserID: newUser.ID, OrganizationID: org.ID, RoleID: 2}
				if err := tx.Create(&member).Error; err != nil {
					return err
				}
			}

			return nil
		})

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "User created successfully",
			"userId":  newUser.ID,
		})
	}
}

// LoginRequest binds the incoming JSON
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// generateJWT creates a new JWT token for a given user
func generateJWT(user models.User) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": user.ID,
		"exp": time.Now().Add(time.Hour * 24 * 30).Unix(), // Token expires in 30 days
	})

	return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}

// Login authenticates a user and returns a JWT
func Login(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		// Find the user by email
		var user models.User
		if err := db.Where("email = ?", req.Email).First(&user).Error; err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
			return
		}

		// Compare the provided password with the stored hash
		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
			return
		}

		// Generate a JWT
		tokenString, err := generateJWT(user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"token": tokenString})
	}
}
