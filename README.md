# OpenBank Sandbox

Open Finance sandbox platform built in Ruby on Rails to showcase consent-driven APIs, partner integrations, and regulated-style simulation flows.

## Status

Phase 0 bootstrap only. This repository currently establishes naming, scope, documentation structure, and engineering expectations. It does not yet contain a Rails application scaffold, OAuth simulation layer, webhook delivery engine, or seeded bank data.

## Product intent

OpenBank Sandbox is planned as a developer-facing sandbox for fintechs and B2B partners that need to test Open Finance-style consent, accounts, balances, transactions, payment initiation, error scenarios, and signed webhooks without depending on real banking infrastructure.

## Planned stack

- Ruby on Rails API
- PostgreSQL
- Redis
- Solid Queue or Sidekiq
- JWT and OAuth simulation
- OpenAPI
- OpenTelemetry
- Prometheus and Grafana
- Docker Compose
- RSpec
- k6

## Engineering focus

This project is meant to demonstrate:

- consent-centric state machines with permission-scoped resource access
- API-first sandbox design for partner integration testing
- scenario-driven behavior changes for QA and conformance simulation
- signed webhooks with retry, replay, and delivery auditability
- idempotent payment initiation and correlation-aware request tracing
- security-oriented testing around scopes, token validity, and tenant boundaries

## Bootstrap contents

- repository initialized and synchronized with GitHub
- mandatory documentation folders created
- scenario documentation folder prepared under `docs/scenarios/`
- baseline engineering spec captured in `docs/engineering-baseline.md`

## Next phase

The first implementation slice should prioritize developer apps, consent lifecycle, permission checks, token simulation, accounts and balances APIs, sandbox scenarios, and webhook delivery semantics.
