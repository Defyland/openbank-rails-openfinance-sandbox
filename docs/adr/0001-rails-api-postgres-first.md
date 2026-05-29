# ADR 0001: Rails API With PostgreSQL Primary

## Status

Accepted

## Context

OpenBank Sandbox must look like a real partner-facing banking API while remaining easy to run during portfolio review. The product needs relational consistency, transaction boundaries, schema constraints, request tests, and clear operational defaults.

## Decision

Use Rails 8 API mode as a modular monolith with PostgreSQL as the primary database target. Keep a SQLite fallback behind `DATABASE_ADAPTER=sqlite3` for deterministic local tests and review environments where PostgreSQL is unavailable.

## Consequences

- Rails gives mature request testing, migrations, validations, Active Job, and security defaults.
- PostgreSQL supports the target production posture: foreign keys, check constraints, transactional payment updates, and operational familiarity.
- SQLite fallback speeds local validation but is not the production recommendation.
- Domain modules must remain explicit so the monolith does not become controller-heavy.
