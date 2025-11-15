package main

import (
	"log"
	"os"

	"github.com/RvShivam/inventify/internal/db"
	"github.com/RvShivam/inventify/internal/handlers"
	"github.com/RvShivam/inventify/internal/middleware"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Fatal("Error loading .env file")
	}

	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		log.Fatal("DB_DSN is not set in env")
	}

	dbconn, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Error connecting to database: ", err)
	}

	// AutoMigrate models in safe order (parents first)
	if err := dbconn.AutoMigrate(
		// Core user/org models
		&models.User{},
		&models.Organization{},
		&models.OrganizationMember{},

		// Category & mapping
		&models.Category{},
		&models.CategoryMapping{},

		// Channels
		&models.Channel{},

		// Products & related
		&models.Product{},
		&models.ProductImage{},
		&models.ProductChannel{},
		&models.ProductChannelOverride{},

		// Channel-specific product tables (1:1)
		&models.ProductWoo{},
		&models.ProductONDC{},

		// Seller locations & per-location stock
		&models.SellerLocation{},
		&models.ProductLocationStock{},

		// Inventory
		&models.InventoryReservation{},
		&models.InventoryMovement{},

		// Publish logs
		&models.ChannelPublishLog{},

		// Woo store connection tables
		&models.WooStore{},
		&models.WooStoreWebhook{},
	); err != nil {
		log.Fatal("AutoMigrate failed: ", err)
	}

	log.Println("AutoMigrate completed")

	// Run DB-level migrations
	if err := db.RunPostgresMigrations(dbconn); err != nil {
		log.Fatal("Error running SQL migrations: ", err)
	}

	log.Println("Postgres-level migrations applied")

	// Router & routes
	router := gin.Default()
	router.Use(cors.Default())

	router.POST("/signup", handlers.Signup(dbconn))
	router.POST("/login", handlers.Login(dbconn))

	api := router.Group("/api")
	api.Use(middleware.RequireAuth)
	{
		api.GET("/dashboard", handlers.GetDashboard(dbconn))
		// add other protected routes like /products here
	}

	log.Println("Starting server on port 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatal("Failed to start server: ", err)
	}
}
