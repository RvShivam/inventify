package config

import (
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration, loaded once at startup.
type Config struct {
	// Server
	Port string

	// Database
	DBDSN string

	// JWT
	JWTSecret          string
	AccessTokenExpiry  time.Duration
	RefreshTokenExpiry time.Duration

	// RabbitMQ
	RabbitMQURL string

	// Rate Limiting
	SignupRateLimit  int // requests per minute
	LoginRateLimit   int // requests per minute
	RefreshRateLimit int // requests per minute
}

// Load reads environment variables and returns a Config.
// It will attempt to load a .env file but won't fail if one doesn't exist.
func Load() *Config {
	// Best-effort .env load (useful for local dev)
	_ = godotenv.Load()

	return &Config{
		Port:               getEnv("PORT", "8080"),
		DBDSN:              getEnvRequired("DB_DSN"),
		JWTSecret:          getEnvRequired("JWT_SECRET"),
		AccessTokenExpiry:  getDurationMinutes("ACCESS_TOKEN_EXPIRY_MINUTES", 15),
		RefreshTokenExpiry: getDurationDays("REFRESH_TOKEN_EXPIRY_DAYS", 7),
		RabbitMQURL:        getEnv("RABBITMQ_URL", ""),
		SignupRateLimit:    getEnvInt("SIGNUP_RATE_LIMIT", 5),
		LoginRateLimit:     getEnvInt("LOGIN_RATE_LIMIT", 10),
		RefreshRateLimit:   getEnvInt("REFRESH_RATE_LIMIT", 10),
	}
}

// ── helpers ────────────────────────────────────────────────

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvRequired(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("FATAL: required env var %s is not set", key)
	}
	return v
}

func getEnvInt(key string, fallback int) int {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		log.Printf("WARN: invalid integer for %s=%q, using default %d", key, v, fallback)
		return fallback
	}
	return n
}

func getDurationMinutes(key string, fallbackMinutes int) time.Duration {
	return time.Duration(getEnvInt(key, fallbackMinutes)) * time.Minute
}

func getDurationDays(key string, fallbackDays int) time.Duration {
	return time.Duration(getEnvInt(key, fallbackDays)) * 24 * time.Hour
}
