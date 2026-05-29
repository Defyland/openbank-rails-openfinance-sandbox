# OpenBank Sandbox Engineering Baseline

This repository follows the initiative-wide standards below.

## Mandatory outcomes

- product-grade `README.md` with product and engineering sections
- `openapi.yaml` once the HTTP surface exists
- `docs/adr/`, `docs/architecture/`, `docs/benchmarks/`, `docs/api/`, `docs/diagrams/`, and `docs/runbooks/`
- atomic Conventional Commit history
- GitHub Actions for lint, tests, security, build, coverage, and OpenAPI validation
- observability with structured logs, metrics, traces, request IDs, and readiness endpoints
- documented k6 performance baselines

## OpenBank Sandbox-specific emphasis

- consent as the core aggregate for authorization and data access
- permission and scope checks across every simulated Open Finance endpoint
- scenario engine support for happy-path and failure-mode partner testing
- signed webhook delivery with retry, replay, and delivery history
- idempotent payment initiation with client-scoped external references
- security coverage for revoked consents, expired tokens, and cross-client isolation

## Phase 0 boundary

This repository intentionally stops before scaffolding Rails, OAuth simulation, seeded datasets, or webhook workers. The goal of this phase is only to lock scope and standards.
