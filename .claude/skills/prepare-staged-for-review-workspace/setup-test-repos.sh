#!/bin/bash
# Setup 4 test repos with staged changes for prepare-staged-for-review evals
set -e

BASE="/Users/josh/.claude/skills/prepare-staged-for-review-workspace/test-repos"
rm -rf "$BASE"
mkdir -p "$BASE"

# ============================================================
# TEST REPO 1: Go service with boundary violations
# ============================================================
REPO1="$BASE/go-order-service"
mkdir -p "$REPO1"
cd "$REPO1"
git init
git config user.email "test@test.com"
git config user.name "Test"

# Base files (initial commit — clean)
mkdir -p domain service api

cat > go.mod << 'EOF'
module github.com/example/order-service

go 1.22
EOF

cat > domain/order.go << 'EOF'
package domain

import "time"

// Order represents a customer order in the system.
type Order struct {
	ID        string
	Customer  Customer
	Items     []LineItem
	CreatedAt time.Time
	Status    OrderStatus
}

type OrderStatus string

const (
	OrderPending   OrderStatus = "pending"
	OrderConfirmed OrderStatus = "confirmed"
	OrderShipped   OrderStatus = "shipped"
)

type Customer struct {
	ID      string
	Name    string
	Address Address
}

type Address struct {
	Street  string
	City    string
	ZipCode string
}

type LineItem struct {
	ProductID string
	Quantity  int
	PriceEach int64 // cents
}

// GetCustomer returns the customer associated with this order.
func (o Order) GetCustomer() Customer { return o.Customer }

// GetAddress returns the customer's address.
func (c Customer) GetAddress() Address { return c.Address }

// GetZipCode returns the zip code of the address.
func (a Address) GetZipCode() string { return a.ZipCode }
EOF

cat > service/order_service.go << 'EOF'
package service

import (
	"context"
	"fmt"

	"github.com/example/order-service/domain"
)

// OrderRepository defines persistence operations for orders.
type OrderRepository interface {
	Save(ctx context.Context, order domain.Order) error
	FindByID(ctx context.Context, id string) (domain.Order, error)
}

// OrderService handles order business logic.
type OrderService struct {
	repo OrderRepository
}

// NewOrderService creates an OrderService with the given repository.
func NewOrderService(repo OrderRepository) *OrderService {
	return &OrderService{repo: repo}
}

// PlaceOrder validates and persists a new order.
func (s *OrderService) PlaceOrder(ctx context.Context, order domain.Order) error {
	if len(order.Items) == 0 {
		return fmt.Errorf("order must have at least one item")
	}
	order.Status = domain.OrderPending
	return s.repo.Save(ctx, order)
}
EOF

cat > api/handler.go << 'EOF'
package api

import (
	"encoding/json"
	"net/http"

	"github.com/example/order-service/service"
)

// OrderHandler handles HTTP requests for orders.
type OrderHandler struct {
	svc *service.OrderService
}

// NewOrderHandler creates an OrderHandler.
func NewOrderHandler(svc *service.OrderService) *OrderHandler {
	return &OrderHandler{svc: svc}
}

// HandleCreateOrder processes POST /orders requests.
func (h *OrderHandler) HandleCreateOrder(w http.ResponseWriter, r *http.Request) {
	// implementation omitted for brevity
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
EOF

git add -A
git commit -m "Initial clean structure"

# --- Now stage the changes with boundary violations ---

# 1. domain/order.go: Add import of database/sql (dependency direction violation)
cat > domain/order.go << 'EOF'
package domain

import (
	"database/sql"
	"time"
)

// Order represents a customer order in the system.
type Order struct {
	ID        string
	Customer  Customer
	Items     []LineItem
	CreatedAt time.Time
	Status    OrderStatus
}

type OrderStatus string

const (
	OrderPending   OrderStatus = "pending"
	OrderConfirmed OrderStatus = "confirmed"
	OrderShipped   OrderStatus = "shipped"
)

type Customer struct {
	ID      string
	Name    string
	Address Address
}

type Address struct {
	Street  string
	City    string
	ZipCode string
}

type LineItem struct {
	ProductID string
	Quantity  int
	PriceEach int64 // cents
}

// GetCustomer returns the customer associated with this order.
func (o Order) GetCustomer() Customer { return o.Customer }

// GetAddress returns the customer's address.
func (c Customer) GetAddress() Address { return c.Address }

// GetZipCode returns the zip code of the address.
func (a Address) GetZipCode() string { return a.ZipCode }

// LoadOrderFromDB retrieves an order directly from the database.
// Called by the API handler when the cache misses.
func LoadOrderFromDB(db *sql.DB, id string) (*Order, error) {
	row := db.QueryRow("SELECT id, status, created_at FROM orders WHERE id = $1", id)
	var o Order
	err := row.Scan(&o.ID, &o.Status, &o.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &o, nil
}
EOF

# 2. service/pricing.go: Unnecessary export + upstream knowledge comment + debug print + Law of Demeter (method chains)
cat > service/pricing.go << 'EOF'
package service

import (
	"fmt"

	"github.com/example/order-service/domain"
)

// FormatPrice converts a price in cents to a display string.
// Called by the OrderHandler in api/handler.go to format prices for the JSON response.
func FormatPrice(cents int64) string {
	dollars := cents / 100
	remainder := cents % 100
	fmt.Println("formatting price:", cents) // debug
	return fmt.Sprintf("$%d.%02d", dollars, remainder)
}

// CalculateOrderTotal computes the total for all line items in an order.
func CalculateOrderTotal(order domain.Order) int64 {
	var total int64
	for _, item := range order.Items {
		total += item.PriceEach * int64(item.Quantity)
	}
	return total
}

// GetShippingZip extracts the shipping zip code from the order's customer.
func GetShippingZip(order domain.Order) string {
	return order.GetCustomer().GetAddress().GetZipCode()
}

// GetOrderSummary builds a summary string for an order.
func GetOrderSummary(order domain.Order) string {
	zip := order.GetCustomer().GetAddress().GetZipCode()
	city := order.GetCustomer().GetAddress().City
	total := CalculateOrderTotal(order)
	return fmt.Sprintf("Order %s: %s to %s %s", order.ID, FormatPrice(total), city, zip)
}
EOF

# 3. domain/validation.go: Circular dependency — domain imports service
cat > domain/validation.go << 'EOF'
package domain

import (
	"fmt"

	"github.com/example/order-service/service"
)

// ValidateOrderMinimum checks if the order total meets the minimum threshold.
// If the total is below $1.00, it returns an error.
func ValidateOrderMinimum(order Order) error {
	total := service.CalculateOrderTotal(order)
	if total < 100 {
		return fmt.Errorf("minimum order is $1.00, got %d cents", total)
	}
	return nil
}
EOF

git add domain/order.go domain/validation.go service/pricing.go


# ============================================================
# TEST REPO 2: TypeScript module with test boundary issues
# ============================================================
REPO2="$BASE/ts-user-module"
mkdir -p "$REPO2"
cd "$REPO2"
git init
git config user.email "test@test.com"
git config user.name "Test"

# Base files (initial commit — clean)
mkdir -p src/internal tests

cat > package.json << 'EOF'
{
  "name": "ts-user-module",
  "version": "1.0.0",
  "type": "module"
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "strict": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
EOF

cat > src/internal/helpers.ts << 'EOF'
// Validates that an email address has a basic valid format.
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Hashes a password using a simple algorithm (placeholder for bcrypt).
export function hashPassword(password: string): string {
  // In production, use bcrypt
  return Buffer.from(password).toString('base64');
}

// Generates a random user ID.
export function generateUserId(): string {
  return `user_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}
EOF

cat > src/user-service.ts << 'EOF'
import { validateEmail, hashPassword, generateUserId } from './internal/helpers';

export interface UserRepository {
  save(user: User): Promise<void>;
  findByEmail(email: string): Promise<User | null>;
}

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
}

export class UserService {
  constructor(private readonly repo: UserRepository) {}

  async register(email: string, password: string): Promise<User> {
    if (!validateEmail(email)) {
      throw new Error('Invalid email format');
    }

    const existing = await this.repo.findByEmail(email);
    if (existing) {
      throw new Error('Email already registered');
    }

    const user: User = {
      id: generateUserId(),
      email,
      passwordHash: hashPassword(password),
      createdAt: new Date(),
    };

    await this.repo.save(user);
    return user;
  }
}
EOF

cat > src/index.ts << 'EOF'
export { UserService } from './user-service';
export type { User, UserRepository } from './user-service';
EOF

cat > tests/user-service.test.ts << 'EOF'
import { UserService, UserRepository, User } from '../src';

class MockRepo implements UserRepository {
  private users: User[] = [];

  async save(user: User): Promise<void> {
    this.users.push(user);
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.users.find(u => u.email === email) ?? null;
  }
}

describe('UserService', () => {
  it('should register a new user', async () => {
    const repo = new MockRepo();
    const service = new UserService(repo);
    const user = await service.register('alice@example.com', 'password123');
    expect(user.email).toBe('alice@example.com');
  });
});
EOF

git add -A
git commit -m "Initial clean structure"

# --- Now stage the changes with boundary violations ---

# 1. Leaky barrel export
cat > src/index.ts << 'EOF'
export { UserService } from './user-service';
export type { User, UserRepository } from './user-service';
export * from './internal/helpers';
EOF

# 2. user-service.ts: Upstream knowledge comment + DI anti-pattern
cat > src/user-service.ts << 'EOF'
import { validateEmail, hashPassword, generateUserId } from './internal/helpers';

export interface UserRepository {
  save(user: User): Promise<void>;
  findByEmail(email: string): Promise<User | null>;
}

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
}

interface PostgresConfig {
  host: string;
  port: number;
  database: string;
}

// UserService handles user registration and lookup.
// Used by the UserRegistration component in pages/register.tsx and the AdminPanel.
export class UserService {
  private repo: UserRepository;
  private auditDb: any;

  constructor(repo: UserRepository, dbConfig: PostgresConfig) {
    this.repo = repo;
    // Connect directly to audit database for logging
    const { Client } = require('pg');
    this.auditDb = new Client({
      host: dbConfig.host,
      port: dbConfig.port,
      database: dbConfig.database,
    });
    this.auditDb.connect();
  }

  async register(email: string, password: string): Promise<User> {
    if (!validateEmail(email)) {
      throw new Error('Invalid email format');
    }

    const existing = await this.repo.findByEmail(email);
    if (existing) {
      throw new Error('Email already registered');
    }

    const user: User = {
      id: generateUserId(),
      email,
      passwordHash: hashPassword(password),
      createdAt: new Date(),
    };

    await this.repo.save(user);

    // Log registration to audit database
    await this.auditDb.query(
      'INSERT INTO audit_log (event, user_id, email) VALUES ($1, $2, $3)',
      ['registration', user.id, user.email]
    );

    return user;
  }
}
EOF

# 3. Test importing from internal paths
cat > tests/user-service.test.ts << 'EOF'
import { UserService, UserRepository, User } from '../src';
import { validateEmail, hashPassword } from '../src/internal/helpers';

class MockRepo implements UserRepository {
  private users: User[] = [];

  async save(user: User): Promise<void> {
    this.users.push(user);
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.users.find(u => u.email === email) ?? null;
  }
}

describe('UserService', () => {
  it('should register a new user', async () => {
    const repo = new MockRepo();
    const service = new UserService(repo, { host: 'localhost', port: 5432, database: 'test' });
    const user = await service.register('alice@example.com', 'password123');
    expect(user.email).toBe('alice@example.com');
  });

  // Testing internal helpers directly — coupled to implementation
  it('should validate emails', () => {
    expect(validateEmail('good@example.com')).toBe(true);
    expect(validateEmail('bad')).toBe(false);
  });

  it('should hash passwords', () => {
    const hash = hashPassword('mypassword');
    expect(hash).toBeTruthy();
    expect(hash).not.toBe('mypassword');
  });
});
EOF

git add src/index.ts src/user-service.ts tests/user-service.test.ts


# ============================================================
# TEST REPO 3: Clean Go code — no boundary violations
# ============================================================
REPO3="$BASE/go-clean-service"
mkdir -p "$REPO3"
cd "$REPO3"
git init
git config user.email "test@test.com"
git config user.name "Test"

mkdir -p internal/domain internal/usecase internal/adapter

cat > go.mod << 'EOF'
module github.com/example/clean-service

go 1.22
EOF

cat > internal/domain/user.go << 'EOF'
package domain

import "time"

// User represents a registered user in the system.
type User struct {
	ID        string
	Email     string
	Name      string
	CreatedAt time.Time
}
EOF

git add -A
git commit -m "Initial domain types"

# --- Staged changes: clean new code ---

# New usecase with proper DI, unexported helpers, good comments
cat > internal/usecase/register.go << 'EOF'
package usecase

import (
	"context"
	"errors"
	"strings"

	"github.com/example/clean-service/internal/domain"
)

// UserRepository defines persistence operations for users.
type UserRepository interface {
	Save(ctx context.Context, user domain.User) error
	FindByEmail(ctx context.Context, email string) (*domain.User, error)
}

// Notifier sends notifications to users.
type Notifier interface {
	SendWelcome(ctx context.Context, user domain.User) error
}

// RegisterService handles new user registration.
type RegisterService struct {
	repo     UserRepository
	notifier Notifier
}

// NewRegisterService creates a RegisterService with the given dependencies.
func NewRegisterService(repo UserRepository, notifier Notifier) *RegisterService {
	return &RegisterService{repo: repo, notifier: notifier}
}

// Register creates a new user account after validating the email
// and checking for duplicates.
func (s *RegisterService) Register(ctx context.Context, email, name string) (*domain.User, error) {
	email = normalizeEmail(email)

	if !isValidEmail(email) {
		return nil, errors.New("invalid email format")
	}

	existing, err := s.repo.FindByEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("email already registered")
	}

	user := domain.User{
		ID:    generateID(),
		Email: email,
		Name:  name,
	}

	if err := s.repo.Save(ctx, user); err != nil {
		return nil, err
	}

	// Best-effort welcome notification — don't fail registration if this errors.
	_ = s.notifier.SendWelcome(ctx, user)

	return &user, nil
}

// normalizeEmail trims whitespace and lowercases the email.
func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// isValidEmail performs basic email format validation.
func isValidEmail(email string) bool {
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}

// generateID creates a unique identifier for a new user.
func generateID() string {
	// In production, use uuid.New().String()
	return "usr_placeholder"
}
EOF

# New adapter implementing the interface
cat > internal/adapter/postgres_repo.go << 'EOF'
package adapter

import (
	"context"
	"database/sql"

	"github.com/example/clean-service/internal/domain"
	"github.com/example/clean-service/internal/usecase"
)

// Compile-time check that PostgresUserRepo satisfies UserRepository.
var _ usecase.UserRepository = (*PostgresUserRepo)(nil)

// PostgresUserRepo implements UserRepository using PostgreSQL.
type PostgresUserRepo struct {
	db *sql.DB
}

// NewPostgresUserRepo creates a PostgresUserRepo with the given database connection.
func NewPostgresUserRepo(db *sql.DB) *PostgresUserRepo {
	return &PostgresUserRepo{db: db}
}

// Save persists a user to the database.
func (r *PostgresUserRepo) Save(ctx context.Context, user domain.User) error {
	_, err := r.db.ExecContext(ctx,
		"INSERT INTO users (id, email, name, created_at) VALUES ($1, $2, $3, NOW())",
		user.ID, user.Email, user.Name,
	)
	return err
}

// FindByEmail looks up a user by email address. Returns nil if not found.
func (r *PostgresUserRepo) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	var u domain.User
	err := r.db.QueryRowContext(ctx,
		"SELECT id, email, name, created_at FROM users WHERE email = $1", email,
	).Scan(&u.ID, &u.Email, &u.Name, &u.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}
EOF

git add internal/usecase/register.go internal/adapter/postgres_repo.go


# ============================================================
# TEST REPO 4: Clean TypeScript code — no boundary violations
# ============================================================
REPO4="$BASE/ts-clean-module"
mkdir -p "$REPO4"
cd "$REPO4"
git init
git config user.email "test@test.com"
git config user.name "Test"

mkdir -p src tests

cat > package.json << 'EOF'
{
  "name": "ts-clean-module",
  "version": "1.0.0",
  "type": "module"
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "strict": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
EOF

# Initial commit — just the interfaces
cat > src/types.ts << 'EOF'
// Core domain types for the notification system.

export interface Notification {
  id: string;
  userId: string;
  channel: NotificationChannel;
  subject: string;
  body: string;
  sentAt: Date | null;
  status: NotificationStatus;
}

export type NotificationChannel = 'email' | 'sms' | 'push';
export type NotificationStatus = 'pending' | 'sent' | 'failed';
EOF

cat > src/index.ts << 'EOF'
export type { Notification, NotificationChannel, NotificationStatus } from './types';
EOF

git add -A
git commit -m "Initial domain types"

# --- Staged changes: clean new code with proper boundaries ---

# Ports (interfaces for external dependencies — injected, not imported)
cat > src/ports.ts << 'EOF'
import type { Notification } from './types';

// NotificationSender abstracts the delivery mechanism.
// Implementations live in infrastructure — this module only depends on this contract.
export interface NotificationSender {
  send(notification: Notification): Promise<void>;
}

// NotificationStore abstracts persistence.
export interface NotificationStore {
  save(notification: Notification): Promise<void>;
  findByUserId(userId: string): Promise<Notification[]>;
}
EOF

# Service — depends only on interfaces, not implementations
cat > src/notification-service.ts << 'EOF'
import type { Notification, NotificationChannel } from './types';
import type { NotificationSender, NotificationStore } from './ports';

// NotificationService coordinates sending and persisting notifications.
// Dependencies are injected via constructor — no infrastructure imports.
export class NotificationService {
  constructor(
    private readonly sender: NotificationSender,
    private readonly store: NotificationStore,
  ) {}

  async notify(
    userId: string,
    channel: NotificationChannel,
    subject: string,
    body: string,
  ): Promise<Notification> {
    const notification: Notification = {
      id: generateId(),
      userId,
      channel,
      subject,
      body,
      sentAt: null,
      status: 'pending',
    };

    await this.store.save(notification);

    try {
      await this.sender.send(notification);
      notification.status = 'sent';
      notification.sentAt = new Date();
    } catch {
      notification.status = 'failed';
    }

    await this.store.save(notification);
    return notification;
  }

  async getHistory(userId: string): Promise<Notification[]> {
    return this.store.findByUserId(userId);
  }
}

// generateId creates a unique notification ID.
function generateId(): string {
  return crypto.randomUUID();
}
EOF

# Updated barrel — exports only public API, no wildcards, no internals
cat > src/index.ts << 'EOF'
export { NotificationService } from './notification-service';
export type { Notification, NotificationChannel, NotificationStatus } from './types';
export type { NotificationSender, NotificationStore } from './ports';
EOF

# Tests — import through barrel, mock via interfaces, test behavior
cat > tests/notification-service.test.ts << 'EOF'
import {
  NotificationService,
  NotificationSender,
  NotificationStore,
  Notification,
} from '../src';

class MockSender implements NotificationSender {
  sent: Notification[] = [];

  async send(notification: Notification): Promise<void> {
    this.sent.push(notification);
  }
}

class MockStore implements NotificationStore {
  notifications: Notification[] = [];

  async save(notification: Notification): Promise<void> {
    const idx = this.notifications.findIndex(n => n.id === notification.id);
    if (idx >= 0) {
      this.notifications[idx] = notification;
    } else {
      this.notifications.push(notification);
    }
  }

  async findByUserId(userId: string): Promise<Notification[]> {
    return this.notifications.filter(n => n.userId === userId);
  }
}

describe('NotificationService', () => {
  it('should send and persist a notification', async () => {
    const sender = new MockSender();
    const store = new MockStore();
    const service = new NotificationService(sender, store);

    const result = await service.notify('user-1', 'email', 'Welcome', 'Hello!');

    expect(result.status).toBe('sent');
    expect(result.sentAt).not.toBeNull();
    expect(sender.sent).toHaveLength(1);
    expect(store.notifications).toHaveLength(1);
  });

  it('should mark notification as failed when sender throws', async () => {
    const sender: NotificationSender = {
      send: async () => { throw new Error('delivery failed'); },
    };
    const store = new MockStore();
    const service = new NotificationService(sender, store);

    const result = await service.notify('user-2', 'sms', 'Alert', 'System down');

    expect(result.status).toBe('failed');
    expect(result.sentAt).toBeNull();
  });

  it('should return notification history for a user', async () => {
    const sender = new MockSender();
    const store = new MockStore();
    const service = new NotificationService(sender, store);

    await service.notify('user-3', 'email', 'First', 'Body 1');
    await service.notify('user-3', 'push', 'Second', 'Body 2');
    await service.notify('user-other', 'email', 'Other', 'Not this one');

    const history = await service.getHistory('user-3');
    expect(history).toHaveLength(2);
  });
});
EOF

git add src/ports.ts src/notification-service.ts src/index.ts tests/notification-service.test.ts

echo "All 4 test repos created successfully."
echo "Repo 1 (Go violations): $REPO1"
echo "Repo 2 (TS violations): $REPO2"
echo "Repo 3 (Go clean):      $REPO3"
echo "Repo 4 (TS clean):      $REPO4"
