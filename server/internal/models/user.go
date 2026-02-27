package models

import (
	"time"

	"gorm.io/gorm"
)

// ── User ───────────────────────────────────────────────────

type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Name      string         `gorm:"not null" json:"name"`
	Email     string         `gorm:"uniqueIndex;not null" json:"email"`
	Password  string         `gorm:"not null" json:"-"` // never exposed in API
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	Organizations []Organization `gorm:"many2many:organization_members;" json:"organizations,omitempty"`
}

// ── Role ───────────────────────────────────────────────────

type Role struct {
	ID   uint   `gorm:"primaryKey" json:"id"`
	Name string `gorm:"uniqueIndex;not null" json:"name"` // "owner", "admin", "staff"
}

// ── Organization ───────────────────────────────────────────

type Organization struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	Name         string         `gorm:"not null" json:"name"`
	OwnerID      uint           `gorm:"not null;index" json:"owner_id"`
	Owner        User           `gorm:"foreignKey:OwnerID;constraint:OnDelete:CASCADE;" json:"-"`
	ReferralCode string         `gorm:"uniqueIndex" json:"referral_code"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	Users []User `gorm:"many2many:organization_members;" json:"users,omitempty"`
}

// ── OrganizationMember (join table) ────────────────────────

type OrganizationMember struct {
	OrganizationID uint         `gorm:"primaryKey" json:"organization_id"`
	Organization   Organization `gorm:"foreignKey:OrganizationID;constraint:OnDelete:CASCADE;" json:"-"`
	UserID         uint         `gorm:"primaryKey" json:"user_id"`
	User           User         `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;" json:"-"`
	RoleID         uint         `gorm:"not null" json:"role_id"`
	Role           Role         `gorm:"foreignKey:RoleID;constraint:OnDelete:RESTRICT;" json:"-"`
}

// ── RefreshToken ───────────────────────────────────────────

type RefreshToken struct {
	ID        string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID    uint      `gorm:"not null;index" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;" json:"-"`
	ExpiresAt time.Time `gorm:"not null" json:"expires_at"`
	Revoked   bool      `gorm:"default:false" json:"revoked"`
	CreatedAt time.Time `json:"created_at"`
}
