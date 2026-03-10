package api

// Stub for db.UserStore interface — the real implementation is in another package.
// This is here so the eval has context about the dependency.

// In the real codebase, db.UserStore looks like:
//
//	type UserStore interface {
//		CreateUser(ctx context.Context, email, name, password string) (*User, error)
//		GetUser(ctx context.Context, id string) (*User, error)
//	}
//
//	type User struct {
//		ID       string
//		Email    string
//		Name     string
//		Password string // hashed
//	}
