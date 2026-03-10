package db

import "context"

// UserStore defines operations for user persistence.
type UserStore interface {
	CreateUser(ctx context.Context, email, name, password string) (*User, error)
	GetUser(ctx context.Context, id string) (*User, error)
}

// User represents a stored user account.
type User struct {
	ID       string
	Email    string
	Name     string
	Password string // hashed
}
