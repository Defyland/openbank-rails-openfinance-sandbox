# Architecture Overview

OpenBank Sandbox is a Rails API modular monolith. It keeps the integration surface small enough to run locally while preserving the operational and security boundaries expected from a banking-style partner API.

## Runtime Components

- Rails API controllers expose versioned JSON endpoints under `/v1`.
- Security services authenticate client credentials and bearer tokens.
- Domain services coordinate consent creation, token issuance, payment processing, scenarios, and webhook publication.
- Active Record models enforce validations and persistence relationships.
- Active Job executes webhook delivery attempts.
- PostgreSQL is the primary database; SQLite is available for local review and tests.

## Request Flow

1. The request receives `X-Request-ID` and `X-Correlation-ID` handling.
2. The rate limiter calculates a client, token, or IP bucket.
3. The controller authenticates either client credentials or bearer token.
4. Endpoint-specific authorization validates consent status and permissions.
5. Domain services perform transactional mutations.
6. Response headers include request and correlation IDs, plus trace ID when available.

## Boundary Choices

Controllers do not hold business rules beyond parameter shape and authentication entry points. Payment idempotency lives in `Sandbox::PaymentInitiator`, token issuance in `Sandbox::TokenIssuer`, and auth checks in `Security::*` services.

## Deployment Shape

The app can run as one container with a PostgreSQL dependency. Solid Queue can share the database for portfolio scale. If webhook delivery volume grows, the job worker can run as a separate process using the same codebase and database.
