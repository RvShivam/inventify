package repositories

import (
	"github.com/RvShivam/inventify/internal/models"
	"gorm.io/gorm"
)

// UserRepository defines the interface for user-related DB operations.
type UserRepository interface {
	CreateUser(user *models.User) error
	FindByEmail(email string) (*models.User, error)
	FindByID(id uint) (*models.User, error)
	CreateOrganization(org *models.Organization) error
	FindOrganizationByReferral(code string) (*models.Organization, error)
	CreateMember(member *models.OrganizationMember) error
	FindMemberByUserID(userID uint) (*models.OrganizationMember, error)
	SaveRefreshToken(token *models.RefreshToken) error
	FindRefreshToken(id string) (*models.RefreshToken, error)
	RevokeRefreshToken(id string) error
	RevokeAllUserTokens(userID uint) error
	Transaction(fn func(repo UserRepository) error) error
}

// userRepo is the GORM implementation of UserRepository.
type userRepo struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepo{db: db}
}

func (r *userRepo) CreateUser(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *userRepo) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	return &user, err
}

func (r *userRepo) FindByID(id uint) (*models.User, error) {
	var user models.User
	err := r.db.First(&user, id).Error
	return &user, err
}

func (r *userRepo) CreateOrganization(org *models.Organization) error {
	return r.db.Create(org).Error
}

func (r *userRepo) FindOrganizationByReferral(code string) (*models.Organization, error) {
	var org models.Organization
	err := r.db.Where("referral_code = ?", code).First(&org).Error
	return &org, err
}

func (r *userRepo) CreateMember(member *models.OrganizationMember) error {
	return r.db.Create(member).Error
}

func (r *userRepo) FindMemberByUserID(userID uint) (*models.OrganizationMember, error) {
	var member models.OrganizationMember
	err := r.db.Where("user_id = ?", userID).Order("role_id ASC").First(&member).Error
	return &member, err
}

func (r *userRepo) SaveRefreshToken(token *models.RefreshToken) error {
	return r.db.Create(token).Error
}

func (r *userRepo) FindRefreshToken(id string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	err := r.db.Where("id = ? AND revoked = false", id).First(&token).Error
	return &token, err
}

func (r *userRepo) RevokeRefreshToken(id string) error {
	return r.db.Model(&models.RefreshToken{}).Where("id = ?", id).Update("revoked", true).Error
}

func (r *userRepo) RevokeAllUserTokens(userID uint) error {
	return r.db.Model(&models.RefreshToken{}).Where("user_id = ? AND revoked = false", userID).Update("revoked", true).Error
}

// Transaction executes fn within a DB transaction, passing a new repo backed by the TX.
func (r *userRepo) Transaction(fn func(repo UserRepository) error) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		txRepo := &userRepo{db: tx}
		return fn(txRepo)
	})
}
