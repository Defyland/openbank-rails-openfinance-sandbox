# ADR 0004: Hybrid Hotwire Operations UI

## Status

Accepted

## Context

OpenBank Sandbox is primarily a partner API product. Partners integrate through JSON endpoints, client credentials, consent-scoped bearer tokens, and webhook callbacks. Converting the whole product into a browser-first app would weaken that product shape.

At the same time, a production sandbox needs an internal operational surface for support, QA, and platform engineers. These users need to inspect consents, payments, scenarios, and webhooks without crafting curl requests or reading database tables.

## Decision

Keep `/v1` as an API-only boundary and add an authenticated `/ops` backoffice using ERB, Turbo, Stimulus, Importmap, and Propshaft. Browser controllers inherit from `ApplicationController < ActionController::Base`; API controllers inherit from `ApiController < ActionController::API`.

Use Rails authentication conventions with bcrypt for operator login. Keep partner authentication separate through the existing client credential and bearer token services.

## Consequences

- The API remains stable and production-shaped for partner integration tests.
- The repository demonstrates the modern Rails full-stack path where it fits the domain.
- Session and CSRF behavior stay out of API controllers.
- Operational workflows become testable with system tests and Capybara.
- There are now two authentication contexts, so `Current.user` and API request context must stay explicit and separate.
