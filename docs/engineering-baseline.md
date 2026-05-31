# OpenBank Sandbox Engineering Baseline

This repository now implements the functional Rails API slice required by the initiative-wide project spec plus a Rails-native operations console for senior portfolio review.

## Repository commitments

- product-grade `README.md` covering product narrative and engineering depth
- executable Rails API with versioned endpoints under `/v1`
- authenticated `/ops` console built with ERB, Turbo, Stimulus, Importmap, and Propshaft
- Rails auth generator style sessions, `bcrypt`, signed cookies, and fixture-backed operator tests
- `openapi.yaml` as the HTTP contract source of truth
- `docs/adr/`, `docs/architecture/`, `docs/benchmarks/`, `docs/api/`, `docs/diagrams/`, and `docs/runbooks/`
- PostgreSQL primary configuration with SQLite fallback for deterministic local review
- Minitest model, request, failure, authorization, system, and repository compliance coverage
- OpenAPI response contract checks backed by JSON Schema validation
- versioned webhook event contract checks backed by the published JSON schemas
- GitHub Actions for lint, tests, seed validation, security checks, OpenAPI linting, Docker build, and coverage upload
- structured request/correlation IDs, JSON logs, persisted audit events, opt-in OpenTelemetry instrumentation, readiness, liveness, Prometheus metrics, and Grafana dashboard definition
- k6 smoke, load, stress, and spike scripts
- Kamal deployment skeleton with Thruster-backed Docker runtime
- environment-driven SMTP, S3-compatible Active Storage, PostgreSQL backup/restore scripts, and Prometheus alert rules for the remaining production-readiness caveats

## OpenBank-specific emphasis

- consent as the central authorization aggregate
- permission checks across every simulated Open Finance resource endpoint
- app-scoped sandbox scenarios for deterministic partner QA
- signed outbound webhook delivery with retry, replay attempt reset, response status, immutable delivery signatures, and delivery history
- authenticated one-time rotation endpoints for client and webhook signing secrets
- idempotent payment initiation with payload fingerprinting and concurrent insert recovery
- cross-app and cross-customer isolation tests

## Current validation gate

The senior portfolio gate is the project CI command:

```bash
bin/ci
```

Local reviewers without PostgreSQL can still run targeted checks with `DATABASE_ADAPTER=sqlite3`, but the GitHub Actions gate explicitly uses PostgreSQL.

Last local senior gate: 2026-05-29.

Passed checks:

- `bin/ci`: setup, RuboCop, Bundler Audit, Brakeman, Rails tests, system tests, seed replant, OpenAPI lint, and Docker build
- `bin/rails zeitwerk:check`
- `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile`
- `bash -n bin/backup-postgres bin/restore-postgres`
- production-like seed guard smoke with SQLite runtime databases:
  - no flags: 0 users, 0 developer apps, 5 scenarios, 0 audit events
  - explicit flags: 1 operator, 1 developer app, 5 scenarios, 0 audit events
- k6 smoke, load, stress, and spike scripts with measured results under `benchmarks/results/`

Senior review posture:

- Strong hire-level evidence: clear product narrative, Rails-native architecture decisions, scoped API auth, app/customer isolation tests, real-but-injectable webhook delivery, deterministic failure scenarios, operations UI, audit trail, security automation, CI, Docker/Kamal readiness, and measured performance.
- Production caveats to discuss in an interview: external SMTP/storage provider selection, managed PostgreSQL backup/restore drills, real APM/exporter credentials, SLO ownership, webhook egress allowlisting, and horizontal scaling thresholds for moving Solid Queue/Cache/Cable off the primary database.
