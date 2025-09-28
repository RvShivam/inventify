package models

import (
	"gorm.io/gorm"
)

// User : This table stores the personal login information for every individual who has an account,
// regardless of which shop they belong to.
type User struct {
	gorm.Model
	Name          string
	Email         string `gorm:"unique;not null"`
	Password      string `gorm:"not null"`
	ReferredId    uint
	Organizations []Organization `gorm:"many2many:organization_members;"`
}

// Role : This table is a simple lookup list of the different permission levels a user can have within a shop.
type Role struct {
	gorm.Model
	Name string `gorm:"unique"` // "Admin", "Staff"
}

// Organization :This is the central table representing a "Shop."
// All data like products and channels will belong to an organization.
type Organization struct {
	gorm.Model
	Name         string
	OwnerID      uint
	ReferralCode string `gorm:"unique"`
	Users        []User `gorm:"many2many:organization_members;"`
}

type OrganizationMember struct {
	OrganizationID uint `gorm:"primaryKey"`
	UserID         uint `gorm:"primaryKey"`
	RoleID         uint `gorm:"not null"`
}
