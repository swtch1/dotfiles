package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/example/webapp/internal/db"
)

// stubUserStore implements db.UserStore for testing.
type stubUserStore struct {
	createUserFunc func(ctx context.Context, email, name, password string) (*db.User, error)
}

func (s stubUserStore) CreateUser(ctx context.Context, email, name, password string) (*db.User, error) {
	if s.createUserFunc != nil {
		return s.createUserFunc(ctx, email, name, password)
	}
	return &db.User{ID: "default", Email: email, Name: name}, nil
}

func (s stubUserStore) GetUser(ctx context.Context, id string) (*db.User, error) {
	return nil, errors.New("not implemented")
}

// --- Characterization tests: document existing behavior before any changes ---

func TestHandleRegister_ValidRequest_Returns201WithUserJSON(t *testing.T) {
	store := stubUserStore{
		createUserFunc: func(ctx context.Context, email, name, password string) (*db.User, error) {
			return &db.User{ID: "u-123", Email: email, Name: name}, nil
		},
	}

	body := RegisterRequest{Email: "user@example.com", Name: "Jane", Password: "password123"}
	bodyBytes, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	HandleRegister(store).ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, rec.Code)
	}

	if got := rec.Header().Get("Content-Type"); got != "application/json" {
		t.Fatalf("expected Content-Type application/json, got %q", got)
	}

	var resp RegisterResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}

	if resp.ID != "u-123" {
		t.Errorf("expected ID u-123, got %q", resp.ID)
	}
	if resp.Email != "user@example.com" {
		t.Errorf("expected Email user@example.com, got %q", resp.Email)
	}
	if resp.Name != "Jane" {
		t.Errorf("expected Name Jane, got %q", resp.Name)
	}
}

func TestHandleRegister_InvalidJSON_Returns400(t *testing.T) {
	store := stubUserStore{}
	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewBufferString("{invalid"))
	rec := httptest.NewRecorder()

	HandleRegister(store).ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
}

func TestHandleRegister_DatabaseError_Returns500(t *testing.T) {
	store := stubUserStore{
		createUserFunc: func(ctx context.Context, email, name, password string) (*db.User, error) {
			return nil, errors.New("connection refused")
		},
	}

	body := RegisterRequest{Email: "user@example.com", Name: "Jane", Password: "password123"}
	bodyBytes, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	HandleRegister(store).ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status %d, got %d", http.StatusInternalServerError, rec.Code)
	}
}

// --- Validation tests: new behavior via TDD ---

// helper to check validation rejection: expects 400 and store NOT called.
func assertValidationReject(t *testing.T, reqBody RegisterRequest) {
	t.Helper()
	createCalled := false
	store := stubUserStore{
		createUserFunc: func(ctx context.Context, email, name, password string) (*db.User, error) {
			createCalled = true
			return &db.User{ID: "u-1", Email: email, Name: name}, nil
		},
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	HandleRegister(store).ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if createCalled {
		t.Fatal("expected CreateUser not to be called for invalid input")
	}
}

func TestHandleRegister_InvalidEmail_Returns400(t *testing.T) {
	assertValidationReject(t, RegisterRequest{
		Email:    "not-an-email",
		Name:     "Jane",
		Password: "password123",
	})
}

func TestHandleRegister_EmptyName_Returns400(t *testing.T) {
	assertValidationReject(t, RegisterRequest{
		Email:    "user@example.com",
		Name:     "",
		Password: "password123",
	})
}

func TestHandleRegister_WhitespaceOnlyName_Returns400(t *testing.T) {
	assertValidationReject(t, RegisterRequest{
		Email:    "user@example.com",
		Name:     "   ",
		Password: "password123",
	})
}

func TestHandleRegister_NameOver100Chars_Returns400(t *testing.T) {
	longName := ""
	for i := 0; i < 101; i++ {
		longName += "a"
	}
	assertValidationReject(t, RegisterRequest{
		Email:    "user@example.com",
		Name:     longName,
		Password: "password123",
	})
}

func TestHandleRegister_PasswordTooShort_Returns400(t *testing.T) {
	assertValidationReject(t, RegisterRequest{
		Email:    "user@example.com",
		Name:     "Jane",
		Password: "short",
	})
}

func TestHandleRegister_PasswordExactly7Chars_Returns400(t *testing.T) {
	assertValidationReject(t, RegisterRequest{
		Email:    "user@example.com",
		Name:     "Jane",
		Password: "1234567",
	})
}

func TestHandleRegister_PasswordExactly8Chars_Returns201(t *testing.T) {
	store := stubUserStore{
		createUserFunc: func(ctx context.Context, email, name, password string) (*db.User, error) {
			return &db.User{ID: "u-1", Email: email, Name: name}, nil
		},
	}

	body := RegisterRequest{Email: "user@example.com", Name: "Jane", Password: "12345678"}
	bodyBytes, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	HandleRegister(store).ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, rec.Code)
	}
}
