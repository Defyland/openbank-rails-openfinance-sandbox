# Hybrid Rails Stack Implementation Plan

## Objective

Move OpenBank Sandbox closer to the modern Rails production stack while preserving the product's API-first contract. The public `/v1` API remains the partner integration surface. The new Rails full-stack layer is an authenticated `/ops` backoffice for operating scenarios, consents, payments, and webhook deliveries.

## Guiding Decisions

- Keep the repository a modular monolith.
- Keep `/v1` JSON controllers isolated from session, CSRF, and browser concerns.
- Use ERB, Turbo, Stimulus, Importmap, and Propshaft for the operational UI.
- Use Rails authentication conventions with bcrypt for human operators.
- Use PostgreSQL as the production and CI database target.
- Keep SQLite only as a local fallback until Ruby/PostgreSQL availability is standardized on every reviewer machine.
- Use Solid Queue, Solid Cache, and Solid Cable on database-backed infrastructure.
- Add system tests only for flows that exercise real browser behavior.

## Phase 1: Rails Full-Stack Foundation

- Add full-stack gems: `propshaft`, `importmap-rails`, `turbo-rails`, `stimulus-rails`, `bcrypt`, `solid_cable`, `capybara`, and `selenium-webdriver`.
- Enable `ActionController::Base` for browser controllers.
- Move API behavior into `ApiController < ActionController::API`.
- Enable Action Cable and Active Storage.
- Add `config/cable.yml`, `config/storage.yml`, importmap, Stimulus, Turbo, and application assets.

## Phase 2: Authenticated Operations UI

- Add Rails-auth-generator-style `User` and `Session` models.
- Store operator passwords with `has_secure_password`.
- Use signed cookie sessions for `/ops`.
- Add `/session` login/logout routes.
- Add an authenticated `/ops` dashboard with operational metrics.
- Add screens for developer apps, consents, payments, webhooks, and sandbox scenarios.
- Support operational mutations: activate scenario, revoke consent, replay webhook.

## Phase 3: Production Readiness Hardening

- Add fixtures for operators and stable domain data.
- Add system tests with Capybara for login, dashboard access, scenario activation, consent revocation, and webhook replay.
- Update CI to run model/request/system tests.
- Keep Brakeman, Bundler Audit, RuboCop, OpenAPI lint, seed validation, and Docker build gates.
- Add Kamal deployment configuration with placeholders and documented secrets.

## Phase 4: Follow-Up Candidates

- Move local default from SQLite to PostgreSQL after Ruby 3.4 and PostgreSQL are guaranteed in the developer environment.
- Add webhook URL allowlisting and private-network egress controls if the sandbox is hosted for untrusted tenants.
- Add Active Storage-backed conformance evidence uploads if partner certification artifacts become part of the product.
- Add Solid Cable live updates for webhook delivery state if operational users need real-time status.

## Acceptance Criteria

- `/v1` API tests keep passing unchanged.
- `/ops` requires an authenticated operator.
- Operations UI can inspect the same production data used by the API.
- Critical operational mutations are tested through browser-level system tests.
- Documentation makes the hybrid architecture and trade-offs explicit.
