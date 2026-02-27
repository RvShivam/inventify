package services

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	"github.com/RvShivam/inventify/internal/config"
	"github.com/RvShivam/inventify/internal/models"
	"github.com/RvShivam/inventify/internal/repositories"
)

// ── Errors ─────────────────────────────────────────────────

var (
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrEmailTaken         = errors.New("email already in use")
	ErrInvalidReferral    = errors.New("invalid referral code")
	ErrInvalidToken       = errors.New("invalid or expired token")
)

// ── Request / Response DTOs ────────────────────────────────

type SignupRequest struct {
	Name         string `json:"name" binding:"required"`
	Email        string `json:"email" binding:"required,email"`
	Password     string `json:"password" binding:"required,min=8"`
	ShopName     string `json:"shop_name"`
	ReferralCode string `json:"referral_code"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token,omitempty"` // omitted when sent via cookie
}

type ProfileResponse struct {
	ID    uint   `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	OrgID uint   `json:"org_id,omitempty"`
	Role  string `json:"role,omitempty"`
}

// ── AuthService ────────────────────────────────────────────

type AuthService struct {
	repo repositories.UserRepository
	cfg  *config.Config
}

func NewAuthService(repo repositories.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{repo: repo, cfg: cfg}
}

// Signup creates a new user and optionally an organization.
func (s *AuthService) Signup(req SignupRequest) (*TokenPair, uint, error) {
	// Check if email exists
	if existing, _ := s.repo.FindByEmail(req.Email); existing.ID != 0 {
		return nil, 0, ErrEmailTaken
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, 0, err
	}

	var userID uint
	var orgID uint

	err = s.repo.Transaction(func(txRepo repositories.UserRepository) error {
		// Create user
		user := &models.User{
			Name:     req.Name,
			Email:    req.Email,
			Password: string(hash),
		}
		if err := txRepo.CreateUser(user); err != nil {
			return err
		}
		userID = user.ID

		if req.ShopName != "" {
			// Create new org as owner
			code, err := generateReferralCode(4)
			if err != nil {
				return err
			}
			org := &models.Organization{
				Name:         req.ShopName,
				OwnerID:      user.ID,
				ReferralCode: code,
			}
			if err := txRepo.CreateOrganization(org); err != nil {
				return err
			}
			orgID = org.ID

			member := &models.OrganizationMember{
				OrganizationID: org.ID,
				UserID:         user.ID,
				RoleID:         1, // owner
			}
			return txRepo.CreateMember(member)

		} else if req.ReferralCode != "" {
			// Join existing org as staff
			org, err := txRepo.FindOrganizationByReferral(req.ReferralCode)
			if err != nil {
				return ErrInvalidReferral
			}
			orgID = org.ID

			member := &models.OrganizationMember{
				OrganizationID: org.ID,
				UserID:         user.ID,
				RoleID:         3, // staff
			}
			return txRepo.CreateMember(member)
		}

		return nil
	})

	if err != nil {
		return nil, 0, err
	}

	// Generate token pair
	tokens, err := s.generateTokenPair(userID, orgID)
	if err != nil {
		return nil, 0, err
	}

	return tokens, userID, nil
}

// Login authenticates a user and returns a token pair.
func (s *AuthService) Login(req LoginRequest) (*TokenPair, *ProfileResponse, error) {
	user, err := s.repo.FindByEmail(req.Email)
	if err != nil || user.ID == 0 {
		return nil, nil, ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, nil, ErrInvalidCredentials
	}

	// Find membership
	member, _ := s.repo.FindMemberByUserID(user.ID)
	orgID := uint(0)
	roleName := ""
	if member != nil {
		orgID = member.OrganizationID
		switch member.RoleID {
		case 1:
			roleName = "owner"
		case 2:
			roleName = "admin"
		case 3:
			roleName = "staff"
		}
	}

	tokens, err := s.generateTokenPair(user.ID, orgID)
	if err != nil {
		return nil, nil, err
	}

	profile := &ProfileResponse{
		ID:    user.ID,
		Name:  user.Name,
		Email: user.Email,
		OrgID: orgID,
		Role:  roleName,
	}

	return tokens, profile, nil
}

// RefreshTokens validates a refresh token and returns a new pair (rotation).
func (s *AuthService) RefreshTokens(refreshTokenID string) (*TokenPair, error) {
	token, err := s.repo.FindRefreshToken(refreshTokenID)
	if err != nil || token.Revoked || time.Now().After(token.ExpiresAt) {
		return nil, ErrInvalidToken
	}

	// Revoke the old token (rotation)
	_ = s.repo.RevokeRefreshToken(refreshTokenID)

	// Find member for org_id
	member, _ := s.repo.FindMemberByUserID(token.UserID)
	orgID := uint(0)
	if member != nil {
		orgID = member.OrganizationID
	}

	return s.generateTokenPair(token.UserID, orgID)
}

// Logout revokes a specific refresh token.
func (s *AuthService) Logout(refreshTokenID string) error {
	return s.repo.RevokeRefreshToken(refreshTokenID)
}

// GetProfile returns the current user's profile.
func (s *AuthService) GetProfile(userID uint) (*ProfileResponse, error) {
	user, err := s.repo.FindByID(userID)
	if err != nil {
		return nil, err
	}

	member, _ := s.repo.FindMemberByUserID(userID)
	orgID := uint(0)
	roleName := ""
	if member != nil {
		orgID = member.OrganizationID
		switch member.RoleID {
		case 1:
			roleName = "owner"
		case 2:
			roleName = "admin"
		case 3:
			roleName = "staff"
		}
	}

	return &ProfileResponse{
		ID:    user.ID,
		Name:  user.Name,
		Email: user.Email,
		OrgID: orgID,
		Role:  roleName,
	}, nil
}

// ── Internal helpers ───────────────────────────────────────

func (s *AuthService) generateTokenPair(userID, orgID uint) (*TokenPair, error) {
	// Access Token (JWT)
	claims := jwt.MapClaims{
		"sub":    userID,
		"org_id": orgID,
		"exp":    time.Now().Add(s.cfg.AccessTokenExpiry).Unix(),
		"iat":    time.Now().Unix(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	accessStr, err := accessToken.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	// Refresh Token (stored in DB)
	refreshToken := &models.RefreshToken{
		UserID:    userID,
		ExpiresAt: time.Now().Add(s.cfg.RefreshTokenExpiry),
	}
	if err := s.repo.SaveRefreshToken(refreshToken); err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessStr,
		RefreshToken: refreshToken.ID,
	}, nil
}

func generateReferralCode(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
