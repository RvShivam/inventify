package main

import (
	"github.com/RvShivam/inventify/internal/handlers"
	"github.com/RvShivam/inventify/internal/middleware"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"log"
	"os"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Fatal("Error loading .env file")
	}

	dsn := os.Getenv("DB_DSN")
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Error connecting to database")
	}
	err = db.AutoMigrate(&models.User{}, &models.Organization{}, &models.User{}, &models.OrganizationMember{})
	if err != nil {
		return
	}

	log.Println("Database migrated")

	router := gin.Default()
	router.Use(cors.Default())
	router.POST("/signup", handlers.Signup(db))
	router.POST("/login", handlers.Login(db))

	api := router.Group("/api")
	api.Use(middleware.RequireAuth)
	{
		api.GET("/dashboard", handlers.GetDashboard(db))
		// You will add other protected routes like /products here
	}
	log.Println("Starting server on port 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatal("Failed to start server: ", err)
	}
}
