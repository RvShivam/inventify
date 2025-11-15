package db

import (
	"gorm.io/gorm"
)

// RunPostgresMigrations applies DB-level constraints & indexes
// that GORM does NOT automatically create.
// Safe to call after AutoMigrate().
func RunPostgresMigrations(db *gorm.DB) error {

	// Enable pgcrypto for UUID generation
	if err := db.Exec(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`).Error; err != nil {
		return err
	}

	migrations := []string{
		// SKU uniqueness per organization
		`CREATE UNIQUE INDEX IF NOT EXISTS ux_product_org_sku
		 ON products (organization_id, sku)
		 WHERE sku IS NOT NULL;`,

		// ProductChannel uniqueness
		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'ux_product_channel'
		  ) THEN
		    ALTER TABLE product_channels
		      ADD CONSTRAINT ux_product_channel UNIQUE (product_id, channel_id);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		// CategoryMapping uniqueness
		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'ux_category_channel'
		  ) THEN
		    ALTER TABLE category_mappings
		      ADD CONSTRAINT ux_category_channel UNIQUE (category_id, channel);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		// Non-negative prices & stock
		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'chk_regular_price_nonneg'
		  ) THEN
		    ALTER TABLE products
		      ADD CONSTRAINT chk_regular_price_nonneg CHECK (regular_price >= 0);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'chk_sale_price_nonneg'
		  ) THEN
		    ALTER TABLE products
		      ADD CONSTRAINT chk_sale_price_nonneg CHECK (sale_price IS NULL OR sale_price >= 0);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'chk_stock_qty_nonneg'
		  ) THEN
		    ALTER TABLE products
		      ADD CONSTRAINT chk_stock_qty_nonneg CHECK (stock_quantity >= 0);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		// Inventory reservation safety
		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'ux_reservation_product_context'
		  ) THEN
		    ALTER TABLE inventory_reservations
		      ADD CONSTRAINT ux_reservation_product_context UNIQUE (product_id, context_id);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		`DO $$
		BEGIN
		  IF NOT EXISTS (
		    SELECT 1 FROM pg_constraint WHERE conname = 'chk_reserved_qty_pos'
		  ) THEN
		    ALTER TABLE inventory_reservations
		      ADD CONSTRAINT chk_reserved_qty_pos CHECK (reserved_qty > 0);
		  END IF;
		EXCEPTION WHEN duplicate_object THEN
		END$$;`,

		// Helpful indexes
		`CREATE INDEX IF NOT EXISTS idx_product_category ON products (local_category_id);`,
		`CREATE INDEX IF NOT EXISTS idx_publish_product_channel ON channel_publish_logs (product_id, channel);`,
	}

	for _, sql := range migrations {
		if err := db.Exec(sql).Error; err != nil {
			return err
		}
	}

	return nil
}
