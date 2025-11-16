package main

import (
	"log"
	"os"

	"github.com/RvShivam/inventify/internal/db"
	"github.com/RvShivam/inventify/internal/events"
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
	// load env
	if err := godotenv.Load(".env"); err != nil {
		log.Fatal("Error loading .env file")
	}

	// DB
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

	// Init RabbitMQ events (optional — will be NO-OP if RABBITMQ_URL is empty)
	if err := events.InitRabbitMQ(os.Getenv("RABBITMQ_URL")); err != nil {
		log.Fatalf("events.InitRabbitMQ failed: %v", err)
	}
	defer func() {
		err := events.Close()
		if err != nil {

		}
	}()

	// Router & routes
	router := gin.Default()
	router.Use(cors.Default())

	// public auth endpoints
	router.POST("/signup", handlers.Signup(dbconn))
	router.POST("/login", handlers.Login(dbconn))

	// protected API
	api := router.Group("/api")
	api.Use(middleware.RequireAuth)
	{
		api.GET("/dashboard", handlers.GetDashboard(dbconn))

		// Woo store management
		woo := api.Group("/woo_stores")
		{
			woo.POST("", handlers.CreateWooStore(dbconn))                   // create + validate + save (publishes event)
			woo.POST("/:id/test", handlers.TestWooStore(dbconn))            // re-validate stored creds
			woo.POST("/:id/webhooks", handlers.RegisterWooWebhooks(dbconn)) // create webhooks on remote Woo and persist
		}

		// add other protected routes like /products here
	}

	internal := router.Group("/internal")
	internal.Use(middleware.RequireServiceToken())
	{
		internal.POST("/woo/stores/:id/sync_categories", handlers.SyncWooCategories(db))
		internal.POST("/woo/stores/:id/register_webhooks", handlers.InternalRegisterWebhooks(db))
	}

	log.Println("Starting server on port 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatal("Failed to start server: ", err)
	}
}
