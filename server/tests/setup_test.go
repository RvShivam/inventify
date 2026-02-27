package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/RvShivam/inventify/internal/config"
	"github.com/RvShivam/inventify/internal/handlers"
	"github.com/RvShivam/inventify/internal/middleware"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/RvShivam/inventify/internal/repositories"
	"github.com/RvShivam/inventify/internal/services"
)

// TestEnv holds all the test dependencies.
type TestEnv struct {
	Router      *gin.Engine
	DB          *gorm.DB
	Config      *config.Config
	AuthHandler *handlers.AuthHandler
}

// SetupTestEnv creates a test environment with a real Postgres DB (test database).
// Requires a running Postgres instance (from docker-compose).
func SetupTestEnv(t *testing.T) *TestEnv {
	t.Helper()

	cfg := &config.Config{
		Port:               "8080",
		DBDSN:              "host=127.0.0.1 port=5433 user=postgres password=postgres dbname=inventify_test sslmode=disable",
		JWTSecret:          "test-secret-key-for-tests-only",
		AccessTokenExpiry:  15 * 60 * 1e9,  // 15 min as duration
		RefreshTokenExpiry: 7 * 24 * 3600 * 1e9, // 7 days as duration
		SignupRateLimit:    5,
		LoginRateLimit:     10,
		RefreshRateLimit:   10,
	}

	db, err := gorm.Open(postgres.Open(cfg.DBDSN), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		t.Fatalf("Failed to connect to test database: %v\nMake sure PostgreSQL is running and the 'inventify_test' database exists.", err)
	}

	// Clean and migrate
	db.Migrator().DropTable(
		&models.RefreshToken{},
		&models.OrganizationMember{},
		&models.Organization{},
		&models.User{},
		&models.Role{},
	)
	db.AutoMigrate(
		&models.Role{},
		&models.User{},
		&models.Organization{},
		&models.OrganizationMember{},
		&models.RefreshToken{},
	)

	// Seed roles
	roles := []models.Role{{Name: "owner"}, {Name: "admin"}, {Name: "staff"}}
	for _, r := range roles {
		db.Where("name = ?", r.Name).FirstOrCreate(&r)
	}

	// Wire up
	userRepo := repositories.NewUserRepository(db)
	authService := services.NewAuthService(userRepo, cfg)
	authHandler := handlers.NewAuthHandler(authService, cfg)

	// Create router
	gin.SetMode(gin.TestMode)
	router := gin.New()

	signupLimiter := middleware.NewRateLimiter(cfg.SignupRateLimit)
	loginLimiter := middleware.NewRateLimiter(cfg.LoginRateLimit)
	refreshLimiter := middleware.NewRateLimiter(cfg.RefreshRateLimit)

	auth := router.Group("/api/auth")
	{
		auth.POST("/signup", signupLimiter.Middleware(), authHandler.Signup)
		auth.POST("/login", loginLimiter.Middleware(), authHandler.Login)
		auth.POST("/refresh", refreshLimiter.Middleware(), authHandler.Refresh)
		auth.POST("/logout", middleware.RequireAuth(cfg), authHandler.Logout)
	}

	api := router.Group("/api")
	api.Use(middleware.RequireAuth(cfg))
	{
		api.GET("/me", authHandler.GetProfile)
	}

	return &TestEnv{
		Router:      router,
		DB:          db,
		Config:      cfg,
		AuthHandler: authHandler,
	}
}

// ── Helper functions ───────────────────────────────────────

// DoJSON sends a JSON request and returns the response recorder.
func DoJSON(router *gin.Engine, method, path string, body interface{}, headers ...http.Header) *httptest.ResponseRecorder {
	var reqBody *bytes.Buffer
	if body != nil {
		jsonBytes, _ := json.Marshal(body)
		reqBody = bytes.NewBuffer(jsonBytes)
	} else {
		reqBody = bytes.NewBuffer(nil)
	}

	req := httptest.NewRequest(method, path, reqBody)
	req.Header.Set("Content-Type", "application/json")
	for _, h := range headers {
		for k, v := range h {
			for _, vv := range v {
				req.Header.Set(k, vv)
			}
		}
	}

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

// DoJSONWithCookies sends a JSON request with cookies and returns the response recorder.
func DoJSONWithCookies(router *gin.Engine, method, path string, body interface{}, cookies []*http.Cookie, headers ...http.Header) *httptest.ResponseRecorder {
	var reqBody *bytes.Buffer
	if body != nil {
		jsonBytes, _ := json.Marshal(body)
		reqBody = bytes.NewBuffer(jsonBytes)
	} else {
		reqBody = bytes.NewBuffer(nil)
	}

	req := httptest.NewRequest(method, path, reqBody)
	req.Header.Set("Content-Type", "application/json")
	for _, c := range cookies {
		req.AddCookie(c)
	}
	for _, h := range headers {
		for k, v := range h {
			for _, vv := range v {
				req.Header.Set(k, vv)
			}
		}
	}

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

// ParseJSON parses the JSON response body into a map.
func ParseJSON(w *httptest.ResponseRecorder) map[string]interface{} {
	var result map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &result)
	return result
}

// ExtractCookie extracts a named cookie from the response.
func ExtractCookie(w *httptest.ResponseRecorder, name string) *http.Cookie {
	for _, c := range w.Result().Cookies() {
		if c.Name == name {
			return c
		}
	}
	return nil
}
