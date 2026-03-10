package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/mail"
	"strings"
	"unicode/utf8"

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

// HandleRegister creates a new user account with input validation.
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
		return errors.New("invalid email format")
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		return errors.New("name is required")
	}
	if utf8.RuneCountInString(name) > 100 {
		return errors.New("name must be 100 characters or less")
	}

	if len(req.Password) < 8 {
		return errors.New("password must be at least 8 characters")
	}

	return nil
}
