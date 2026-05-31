# OpenBank Sandbox

## What is this product?

OpenBank Sandbox is a Rails monolith that lets fintech partners test Open Finance-style integrations without touching real banking rails. It exposes a stable JSON API for partners and a Hotwire operations console for sandbox operators. It simulates developer app credentials, customer consents, consent-scoped OAuth tokens, accounts, balances, transactions, payment initiation, signed webhooks, and deterministic failure scenarios.

## Problem it solves

Partner teams need repeatable banking integration environments where they can validate permission scopes, consent lifecycle behavior, payment idempotency, webhook replay, and failure handling before certification or production onboarding. Real banking sandboxes are often slow, incomplete, or hard to reset. This project provides an inspectable local sandbox with production-shaped controls.

## Target users

- Fintech backend engineers building Open Finance integrations.
- QA teams validating consent and payment scenarios.
- Platform engineers designing partner onboarding flows.
- Security reviewers checking tenant isolation, token scope enforcement, and auditability.

## Main features

- Developer app registration with generated client credentials.
- Consent creation, authorization, revocation, expiration, and permission scoping.
- OAuth-style bearer token issuance tied to an authorized consent.
- Consent-scoped account, balance, and transaction APIs.
- Idempotent payment initiation with deterministic accept/reject behavior.
- Signed outbound webhook delivery with retry, replay, attempts, response status, and dead-letter state.
- Scenario engine for happy path, payment rejection, expired consent, webhook retry, and slow bank simulations.
- Authenticated `/ops` console for consent audit, payment inspection, scenario control, and webhook replay.
- Health, readiness, Prometheus metrics, structured logs, request IDs, correlation IDs, audit events, and OpenTelemetry instrumentation.

## Architecture overview

The application is a Rails modular monolith. Partner endpoints under `/v1` inherit from `ApiController < ActionController::API` so the HTTP contract remains lean and sessionless. Browser endpoints under `/ops` inherit from `ApplicationController < ActionController::Base` to use Rails sessions, cookies, CSRF protection, ERB, Turbo, Stimulus, Importmap, and Propshaft.

The primary database target is PostgreSQL, and CI exercises PostgreSQL explicitly. A SQLite fallback is available through `DATABASE_ADAPTER=sqlite3` so local review can run without an external database. Background work uses Active Job with Solid Queue in app environments and the test adapter in tests. Production configuration separates primary, cache, queue, and cable databases for Solid Cache, Solid Queue, and Solid Cable.

## Tech stack

- Ruby 3.4.9 target runtime
- Rails 8.1 hybrid monolith
- PostgreSQL primary database
- SQLite local test fallback
- ERB, Turbo, Stimulus, Importmap, and Propshaft
- Active Job, Solid Queue, Solid Cache, and Solid Cable
- Minitest, fixtures, and Capybara system tests
- Rails auth generator style sessions with `bcrypt`
- Opt-in OpenTelemetry SDK and Rails instrumentation
- Prometheus text metrics endpoint
- Docker, Thruster, Kamal, and Docker Compose
- k6 benchmark scripts
- GitHub Actions CI

## Domain model

- `DeveloperApp`: partner tenant, client credentials, one-time webhook signing secret, webhook URL, rate limit, and active scenario.
- `SandboxCustomer`: simulated bank customer with document number, segment, and risk profile.
- `Consent`: core authorization aggregate with status, permissions, expiration, customer, and app scope.
- `AccessToken`: bearer token digest tied to a consent and permission subset.
- `Account`: consent-visible account with balance and status.
- `LedgerTransaction`: account ledger entry used by transaction APIs and payment side effects.
- `PaymentInitiation`: idempotent payment command with request fingerprint and simulated processing result.
- `WebhookDelivery`: signed event delivery record with attempts, retry schedule, replay, and terminal states.
- `SandboxScenario`: persisted catalog entry backed by deterministic scenario definitions.
- `AuditEvent`: operational and API action trail with actor, target, request, correlation, IP, user agent, and metadata context.

## API documentation

`openapi.yaml` is the source of truth for the HTTP contract. Request examples are in `docs/api/http-examples.md`, the standard error envelope is documented in `docs/api/error-format.md`, and partner testing guidance is documented in [docs/api/partner-testing-guide.md](docs/api/partner-testing-guide.md).

Authentication uses two schemes:

- Client credentials: `X-Client-Id` plus `X-Client-Secret` for app, consent, token, scenario, and webhook management.
- Bearer token: `Authorization: Bearer <token>` for consent-scoped account and payment APIs.

OAuth/FAPI behavior is simulated for deterministic partner testing: token issuance is consent-bound, resource access checks token status, consent status, expiration, scopes, app ownership, and customer isolation, but certification-grade mTLS, JWKS, PAR/JAR/JARM, DPoP, and OpenID directory behavior remain outside this sandbox.

## Async or event architecture

Webhook delivery is modeled as an outbox-style table (`webhook_deliveries`). Consent authorization, consent revocation, and payment processing enqueue signed delivery records. `WebhookDeliveryJob` performs outbound HTTP POST attempts, records response status and errors, schedules retries, and moves repeated failures toward a dead-letter state.

The sandbox intentionally persists delivery history before attempting outbound work so API mutations are durable even when partner webhook endpoints fail.

Versioned webhook and consent/payment events are documented in [docs/events/README.md](docs/events/README.md).

## Database design

The schema uses foreign keys, unique indexes, check constraints, request fingerprints, token digests, and optimistic locking on consents. Consistency-sensitive boundaries are documented in `docs/architecture/data-consistency.md`.

Important constraints include:

- unique `developer_apps.client_id`
- unique consent external ID per developer app
- unique token digest
- unique payment idempotency key per developer app
- unique webhook event and idempotency keys
- positive monetary amounts and non-negative account balances
- status check constraints on all stateful aggregates

## Testing strategy

The test suite covers:

- model invariants for credentials, consents, payments, and webhooks
- full partner flow from app creation through payment webhook delivery
- authorization failures and cross-customer isolation
- revoked and expired consent behavior
- idempotency conflict behavior
- rate limiting and standardized error payloads
- OpenAPI and repository evidence compliance
- `/ops` authentication, scenario activation, consent revocation, and webhook replay through Capybara system tests

Run the complete suite with:

```bash
DATABASE_ADAPTER=sqlite3 ruby bin/rails test
DATABASE_ADAPTER=sqlite3 ruby bin/rails test:system
```

## Performance benchmarks

k6 scripts live under `benchmarks/`:

- `smoke.js`
- `load.js`
- `stress.js`
- `spike.js`

The baseline method and current local portfolio result are documented in `docs/benchmarks/methodology.md` and `docs/benchmarks/local-baseline.md`.

## Observability

The API exposes:

- `GET /up` liveness
- `GET /ready` readiness with primary, cache, queue, and cable database probes
- `GET /metrics` Prometheus text metrics
- JSON structured logs in production by default
- `X-Request-ID` and `X-Correlation-ID` response headers
- Opt-in OpenTelemetry Rails instrumentation when `OTEL_ENABLED=true` or an OTLP endpoint is configured
- Prometheus alert rules in `ops/prometheus/alerts.yml`
- Grafana dashboard definition in `observability/grafana/openbank-sandbox-overview.json`

## Security considerations

Security coverage is intentionally product-shaped:

- client secrets and bearer tokens are stored as SHA-256 digests
- webhook signing secrets are returned once and stored encrypted at rest
- bearer tokens are consent-scoped and short-lived
- every account/payment lookup is constrained by consent customer and app
- permissions are enforced per endpoint
- sensitive parameters are filtered from logs
- app-level rate limiting protects APIs from abusive clients
- revoking a consent revokes active tokens
- consent transitions are guarded so duplicate lifecycle calls do not emit duplicate events
- operator sessions expire server-side after inactivity and are trimmed on a recurring schedule
- sensitive operator and partner actions are written to `audit_events`
- webhook payloads are HMAC-SHA256 signed over `signature_timestamp.canonical_json_body`

The threat model and authorization matrix are documented in `docs/security/`. The simulation boundary is documented in [docs/adr/0006-simulated-openfinance-boundary.md](docs/adr/0006-simulated-openfinance-boundary.md), and deployment readiness in [docs/architecture/deployment-readiness.md](docs/architecture/deployment-readiness.md).

## Trade-offs and decisions

- The sandbox uses a modular monolith because the product surface is domain-rich but operationally small.
- The browser console is a hybrid Rails layer, not a React SPA, because operators need fast CRUD-style workflows close to the domain model.
- PostgreSQL is the production target, with SQLite kept only for fast local review and CI portability.
- Solid Queue, Solid Cache, and Solid Cable are used before Redis because this sandbox benefits more from fewer moving parts than independent scaling tiers.
- OAuth is simulated rather than fully implementing FAPI/OIDC because the goal is partner workflow validation, not identity-provider certification.
- Webhook delivery uses a real HTTP adapter in app environments and an injectable test adapter so automated tests stay deterministic without external services.
- Scenario behavior is deterministic by app instead of randomized so QA teams can reproduce failures.
- Production caveats, counterpoints, and escalation paths are documented in `docs/runbooks/production-readiness.md`.

ADRs in `docs/adr/` describe the major decisions.

## How to run locally

Install gems:

```bash
bundle install
```

Run with SQLite fallback:

```bash
DATABASE_ADAPTER=sqlite3 ruby bin/rails db:prepare
DATABASE_ADAPTER=sqlite3 ruby bin/rails db:seed
DATABASE_ADAPTER=sqlite3 ruby bin/rails server
```

In development and test, the default operator login is `ops@example.test` / `password-12345` unless `OPERATOR_EMAIL` and `OPERATOR_PASSWORD` are provided.

In production, bootstrap is explicit:

```bash
bash bin/prepare-runtime-databases
SEED_OPERATOR=true OPERATOR_EMAIL=ops@example.test OPERATOR_PASSWORD='replace-with-16-plus-chars' bin/rails db:seed
SEED_DEMO_DATA=true DEMO_CLIENT_SECRET='replace-with-a-long-random-secret' bin/rails db:seed
```

When running production with SQLite for local smoke tests, set `DATABASE_PATH`, `CACHE_DATABASE_PATH`, `QUEUE_DATABASE_PATH`, and `CABLE_DATABASE_PATH` explicitly so all Solid databases are isolated and inspectable.

Run with Docker Compose and PostgreSQL:

```bash
docker compose up --build
```

## How to run tests

```bash
DATABASE_ADAPTER=sqlite3 ruby bin/rails test
DATABASE_ADAPTER=sqlite3 ruby bin/rails test:system
DATABASE_ADAPTER=sqlite3 ruby bin/rubocop
DATABASE_ADAPTER=sqlite3 ruby bin/brakeman --quiet --no-pager
DATABASE_ADAPTER=sqlite3 ruby bin/bundler-audit
```

The CI workflow runs PostgreSQL-backed Rails tests, system tests, seed validation, OpenAPI linting, Docker build validation, and coverage artifact upload.

## Failure scenarios

Activate a scenario per developer app:

```bash
curl -X PATCH http://localhost:3000/v1/scenarios/payment_rejected/activate \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx"
```

Supported scenarios:

- `happy_path`: all flows succeed.
- `payment_rejected`: payment API persists a rejected payment and emits `payment.rejected`.
- `expired_consent`: token issuance expires the consent and returns forbidden.
- `webhook_retry`: delivery attempts fail and schedule retries.
- `slow_bank`: exposes latency configuration for timeout testing.

## Roadmap

- Add mTLS/JWKS simulation for stronger partner authentication.
- Add FAPI-style authorization code and PAR/JAR simulation.
- Add richer Open Finance Brazil payload profiles.
- Add webhook URL allowlisting/private-network egress controls for shared hosted environments.
- Add multi-currency account fixtures and scheduled transaction imports.
- Add Postgres advisory-lock based payment processing benchmarks.
- Run a real managed PostgreSQL restore drill and attach evidence to `docs/runbooks/postgres-backup-restore.md`.
