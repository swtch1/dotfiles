# Discovery Probing (Mini-Spec, one round)

Because this is a mini-spec, only the highest-risk concern and scope boundary questions were generated.
Per instruction, defaults were applied without waiting for answers.

1. **[High] Invalid timeout behavior**  
   `cmd/server/main.go` currently fails startup only when `STRIPE_SECRET_KEY` is missing, and the timeout is hardcoded to a known-good value (`30`). Introducing `STRIPE_TIMEOUT_SECONDS` adds a new invalid-input path (non-integer/<=0). Should invalid timeout values fail fast at startup for strict config hygiene, or should the service warn and fall back to default to preserve availability?
   - **Default applied:** warn + fallback to `30`.

2. **[Medium] Env var naming/units contract**  
   `internal/billing/NewStripeClient` takes timeout in **seconds** (`int`) and converts to `time.Duration`. Should the env contract stay integer seconds (`STRIPE_TIMEOUT_SECONDS`) to match the constructor, or switch to duration strings (e.g. `30s`) for consistency with broader Go config conventions?
   - **Default applied:** integer seconds via `STRIPE_TIMEOUT_SECONDS`.

3. **[Medium] Scope boundary for code changes**  
   `internal/billing/stripe_client.go` already accepts a timeout parameter, so changing it would be unnecessary blast radius for this request. Confirm this stays a startup-wiring-only change in `cmd/server/main.go`.
   - **Default applied:** main-only implementation path.
