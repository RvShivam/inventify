package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"github.com/RvShivam/inventify/internal/config"
	"github.com/RvShivam/inventify/internal/db"
	"github.com/RvShivam/inventify/internal/handlers"
	"github.com/RvShivam/inventify/internal/middleware"
	"github.com/RvShivam/inventify/internal/repositories"
	"github.com/RvShivam/inventify/internal/services"
)

func main() {
	// ── Load Config ────────────────────────────────────────
	cfg := config.Load()

	// ── Database ───────────────────────────────────────────
	database := db.Connect(cfg.DBDSN)

	// ── Repositories ───────────────────────────────────────
	userRepo := repositories.NewUserRepository(database)

	// ── Services ───────────────────────────────────────────
	authService := services.NewAuthService(userRepo, cfg)

	// ── Handlers ───────────────────────────────────────────
	authHandler := handlers.NewAuthHandler(authService, cfg)

	// ── Router ─────────────────────────────────────────────
	router := gin.Default()

	// CORS
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:3000", "http://localhost:5173"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// ── Rate Limiters ──────────────────────────────────────
	signupLimiter := middleware.NewRateLimiter(cfg.SignupRateLimit)
	loginLimiter := middleware.NewRateLimiter(cfg.LoginRateLimit)
	refreshLimiter := middleware.NewRateLimiter(cfg.RefreshRateLimit)

	// ── Public Auth Routes ─────────────────────────────────
	auth := router.Group("/api/auth")
	{
		auth.POST("/signup", signupLimiter.Middleware(), authHandler.Signup)
		auth.POST("/login", loginLimiter.Middleware(), authHandler.Login)
		auth.POST("/refresh", refreshLimiter.Middleware(), authHandler.Refresh)
		auth.POST("/logout", middleware.RequireAuth(cfg), authHandler.Logout)
	}

	// ── Protected Routes ───────────────────────────────────
	api := router.Group("/api")
	api.Use(middleware.RequireAuth(cfg))
	{
		api.GET("/me", authHandler.GetProfile)
	}

	// ── Start Server ───────────────────────────────────────
	log.Printf("Server starting on port %s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("FATAL: failed to start server: %v", err)
	}
}
