package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/example/webapp/internal/db"
)

type fakeUserStore struct {
	createCalled bool
	createFn     func(ctx context.Context, email, name, password string) (*db.User, error)
}

func (f *fakeUserStore) CreateUser(ctx context.Context, email, name, password string) (*db.User, error) {
	f.createCalled = true
	if f.createFn != nil {
		return f.createFn(ctx, email, name, password)
	}
	return &db.User{ID: "u-1", Email: email, Name: name}, nil
}

func (f *fakeUserStore) GetUser(ctx context.Context, id string) (*db.User, error) {
	return nil, errors.New("not implemented")
}

func TestHandleRegister_RejectsInvalidEmail(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	req := httptest.NewRequest(http.MethodPost, "/register", strings.NewReader(`{"email":"not-an-email","name":"Jane","password":"password123"}`))
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "invalid email") {
		t.Fatalf("expected invalid email error, got %q", rec.Body.String())
	}
	if store.createCalled {
		t.Fatal("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsEmptyName(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	req := httptest.NewRequest(http.MethodPost, "/register", strings.NewReader(`{"email":"jane@example.com","name":"","password":"password123"}`))
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "invalid name") {
		t.Fatalf("expected invalid name error, got %q", rec.Body.String())
	}
	if store.createCalled {
		t.Fatal("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsTooLongName(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	tooLongName := strings.Repeat("a", 101)
	body := `{"email":"jane@example.com","name":"` + tooLongName + `","password":"password123"}`
	req := httptest.NewRequest(http.MethodPost, "/register", strings.NewReader(body))
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "invalid name") {
		t.Fatalf("expected invalid name error, got %q", rec.Body.String())
	}
	if store.createCalled {
		t.Fatal("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsShortPassword(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	req := httptest.NewRequest(http.MethodPost, "/register", strings.NewReader(`{"email":"jane@example.com","name":"Jane","password":"short"}`))
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "invalid password") {
		t.Fatalf("expected invalid password error, got %q", rec.Body.String())
	}
	if store.createCalled {
		t.Fatal("expected CreateUser not to be called")
	}
}

func TestHandleRegister_CreatesUserForValidInput(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	req := httptest.NewRequest(http.MethodPost, "/register", strings.NewReader(`{"email":"jane@example.com","name":"Jane","password":"password123"}`))
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, rec.Code)
	}
	if !store.createCalled {
		t.Fatal("expected CreateUser to be called")
	}

	var resp RegisterResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if resp.Email != "jane@example.com" {
		t.Fatalf("expected response email to be jane@example.com, got %q", resp.Email)
	}
	if resp.Name != "Jane" {
		t.Fatalf("expected response name to be Jane, got %q", resp.Name)
	}
}
