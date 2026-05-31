# Common Issues Runbook

## Database Not Ready

Symptoms:

- `GET /ready` returns 503.
- Rails logs show connection errors.

Actions:

1. Confirm `DATABASE_ADAPTER`, `POSTGRES_HOST`, `POSTGRES_USER`, and `POSTGRES_PASSWORD`.
2. Run `ruby bin/rails db:prepare`.
3. With Docker Compose, check `docker compose ps postgres`.

## Invalid Client Credentials

Symptoms:

- API returns `401 unauthorized`.

Actions:

1. Confirm `X-Client-Id` and `X-Client-Secret` are from the same app creation response.
2. Check `developer_apps.status` is `active`.
3. Regenerate an app in sandbox if the one-time secret was lost.

## Token Cannot Access Account

Symptoms:

- API returns `403 forbidden` for account, balance, transaction, or payment endpoint.

Actions:

1. Confirm the consent is `authorized` and not expired.
2. Confirm the token permissions include the endpoint permission.
3. Confirm the account belongs to the consent customer.

## Payment Idempotency Conflict

Symptoms:

- `POST /v1/payments` returns `409 conflict`.

Actions:

1. Reuse the same idempotency key only with exactly the same payload.
2. Generate a new idempotency key for a changed payment request.
3. Inspect the existing payment by listing `/v1/payments`.

## Webhook Delivery Failing

Symptoms:

- Delivery status is `failed` or `dead`.

Actions:

1. Check active scenario; `webhook_retry` intentionally fails attempts.
2. Inspect `last_response_status`, `last_error`, `attempts_count`, and `next_attempt_at`.
3. Use `POST /v1/webhook_deliveries/:id/replay` after fixing the partner endpoint.
