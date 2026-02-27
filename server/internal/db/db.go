package db

import (
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/RvShivam/inventify/internal/models"
)

// Connect opens a GORM connection to Postgres and runs AutoMigrate.
func Connect(dsn string) *gorm.DB {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("FATAL: failed to connect to database: %v", err)
	}

	// Configure connection pool
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("FATAL: failed to get underlying sql.DB: %v", err)
	}
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(10)

	// AutoMigrate all models
	if err := db.AutoMigrate(
		&models.Role{},
		&models.User{},
		&models.Organization{},
		&models.OrganizationMember{},
		&models.RefreshToken{},
	); err != nil {
		log.Fatalf("FATAL: AutoMigrate failed: %v", err)
	}

	// Seed default roles
	seedRoles(db)

	log.Println("Database connected and migrated successfully")
	return db
}

func seedRoles(db *gorm.DB) {
	roles := []models.Role{
		{Name: "owner"},
		{Name: "admin"},
		{Name: "staff"},
	}
	for _, r := range roles {
		// FirstOrCreate to avoid duplicates on restart
		db.Where("name = ?", r.Name).FirstOrCreate(&r)
	}
}
