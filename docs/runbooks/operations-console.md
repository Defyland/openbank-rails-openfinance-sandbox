# Operations Console Runbook

## Purpose

The `/ops` console is the browser-facing control plane for sandbox operators. It keeps the partner API under `/v1` stable while exposing operational workflows through Rails ERB, Turbo, Stimulus, Importmap, and Propshaft.

## Access

Seed the first operator with:

```bash
OPERATOR_EMAIL=ops@example.test OPERATOR_PASSWORD=password-12345 bin/rails db:seed
```

In production, require explicit bootstrap flags:

```bash
SEED_OPERATOR=true OPERATOR_EMAIL=ops@example.test OPERATOR_PASSWORD='replace-with-16-plus-chars' bin/rails db:seed
```

Optional demo partner data is also gated in production:

```bash
SEED_DEMO_DATA=true DEMO_CLIENT_SECRET='replace-with-a-long-random-secret' bin/rails db:seed
```

Then sign in at `/session/new`. Passwords are stored through `has_secure_password` and `bcrypt`; authenticated browser sessions are tracked in the `sessions` table, expire after inactivity, and are trimmed by a recurring production job.

## Daily Workflows

- Use `/ops` to inspect platform health signals, recent payments, and webhook pressure.
- Use `/ops/developer_apps` to inspect partner tenants, webhook URLs, limits, and active scenarios.
- Use `/ops/consents` to audit consent status, customer scope, permissions, tokens, and payments under consent.
- Use `/ops/scenarios` to activate deterministic failure behavior per partner app.
- Use `/ops/webhook_deliveries` to inspect signatures, delivery state, attempts, payloads, and replay failed deliveries.
- Use `/ops/audit_events` to inspect operator sessions, scenario changes, consent lifecycle changes, payments, webhook replays, request IDs, correlation IDs, IP addresses, and user agents.

## Production Notes

- Keep `/v1` on `ApiController < ActionController::API`; do not add browser session or CSRF behavior to API endpoints.
- Keep `/ops` on `ApplicationController < ActionController::Base` so Rails sessions, cookies, CSRF protection, Turbo, and Stimulus remain available.
- Use strong operator passwords and rotate any bootstrap password after first deploy.
- Set `RAILS_MASTER_KEY`, `POSTGRES_PASSWORD`, `OPERATOR_EMAIL`, `OPERATOR_PASSWORD`, and registry credentials as Kamal secrets.
- Keep Solid Queue, Solid Cache, and Solid Cable databases separate in production to isolate operational pressure from primary API reads and writes.
- Enable OpenTelemetry only when an OTLP endpoint is intentionally configured.
- Keep `RAILS_LOG_FORMAT=json` in production unless the hosting platform requires plain text parsing.
- Use `/ready` as the readiness target because it probes primary, cache, queue, and cable databases.

## Validation

Run the browser workflow tests with:

```bash
DATABASE_ADAPTER=sqlite3 ruby bin/rails test:system
```

The system suite uses Capybara's rack test driver for deterministic CI coverage without requiring a local browser.
