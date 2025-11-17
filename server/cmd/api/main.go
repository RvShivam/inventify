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
		&models.User{},
		&models.Organization{},
		&models.OrganizationMember{},
		&models.Category{},
		&models.CategoryMapping{},
		&models.Channel{},
		&models.Product{},
		&models.ProductImage{},
		&models.ProductChannel{},
		&models.ProductChannelOverride{},
		&models.ProductWoo{},
		&models.ProductONDC{},
		&models.SellerLocation{},
		&models.ProductLocationStock{},
		&models.InventoryReservation{},
		&models.InventoryMovement{},
		&models.ChannelPublishLog{},
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
	rabbitErr := events.InitRabbitMQ(os.Getenv("RABBITMQ_URL"))
	if rabbitErr != nil {
		log.Fatalf("events.InitRabbitMQ failed: %v", rabbitErr)
	}
	// Only close if Init succeeded
	defer func() {
		if err := events.Close(); err != nil {
			log.Println("events.Close error:", err)
		}
	}()

	// Router & routes
	router := gin.Default()
	// Consider restricting CORS origins in production
	router.Use(cors.Default())

	// public auth endpoints
	router.POST("/signup", handlers.Signup(dbconn))
	router.POST("/login", handlers.Login(dbconn))

	// public webhook receiver (Woo -> our server)
	router.POST("/webhooks/woo", handlers.WooWebhookReceiver(dbconn))

	// protected API (user auth)
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

	// internal service-only endpoints (protected by SERVICE_TOKEN)
	internal := router.Group("/internal")
	internal.Use(middleware.RequireServiceToken())
	{
		internal.POST("/woo/stores/:id/sync_categories", handlers.SyncWooCategories(dbconn))
		internal.POST("/woo/stores/:id/register_webhooks", handlers.InternalRegisterWebhooks(dbconn))
	}

	log.Println("Starting server on port 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatal("Failed to start server: ", err)
	}
}
