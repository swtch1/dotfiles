package db

import "context"

type UserStore interface {
	CreateUser(ctx context.Context, email, name, password string) (*User, error)
	GetUser(ctx context.Context, id string) (*User, error)
}

type User struct {
	ID       string
	Email    string
	Name     string
	Password string
}
