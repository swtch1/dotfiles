package api

import (
	"encoding/json"
	"net/http"
	"net/mail"
	"strings"

	"github.com/example/webapp/internal/db"
)

type RegisterRequest struct {
	Email    string `json:"email"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

type RegisterResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

// HandleRegister creates a new user account.
// No validation currently — accepts anything and lets the DB complain.
func HandleRegister(store db.UserStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RegisterRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		if err := validateRegisterRequest(req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		user, err := store.CreateUser(r.Context(), req.Email, req.Name, req.Password)
		if err != nil {
			http.Error(w, "failed to create user", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(RegisterResponse{
			ID:    user.ID,
			Email: user.Email,
			Name:  user.Name,
		})
	}
}

func validateRegisterRequest(req RegisterRequest) error {
	if _, err := mail.ParseAddress(req.Email); err != nil {
		return errInvalidEmail
	}
	if strings.TrimSpace(req.Name) == "" {
		return errInvalidName
	}
	if len(req.Name) > 100 {
		return errInvalidName
	}
	if len(req.Password) < 8 {
		return errInvalidPassword
	}

	return nil
}

var (
	errInvalidEmail    = &requestValidationError{message: "invalid email"}
	errInvalidName     = &requestValidationError{message: "invalid name"}
	errInvalidPassword = &requestValidationError{message: "invalid password"}
)

type requestValidationError struct {
	message string
}

func (e *requestValidationError) Error() string {
	return e.message
}
