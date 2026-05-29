# Authorization Matrix

| Endpoint | Authentication | Required permission | Scope rule |
| --- | --- | --- | --- |
| `POST /v1/developer_apps` | none | none | creates new app |
| `GET /v1/developer_app` | client credentials | none | authenticated app only |
| `GET /v1/consents` | client credentials | none | app consents only |
| `POST /v1/consents` | client credentials | none | app creates consent for existing sandbox customer |
| `PATCH /v1/consents/:id/authorize` | client credentials | none | consent must belong to app |
| `PATCH /v1/consents/:id/revoke` | client credentials | none | consent must belong to app |
| `POST /v1/oauth/token` | client credentials | none | consent must belong to app and be authorized |
| `GET /v1/accounts` | bearer token | `ACCOUNTS_READ` | consent customer accounts only |
| `GET /v1/accounts/:id` | bearer token | `ACCOUNTS_READ` | account customer must match consent customer |
| `GET /v1/accounts/:id/balances` | bearer token | `BALANCES_READ` | account customer must match consent customer |
| `GET /v1/accounts/:id/transactions` | bearer token | `TRANSACTIONS_READ` | account customer must match consent customer |
| `POST /v1/payments` | bearer token | `PAYMENTS_INITIATE` | payer account must match consent customer |
| `GET /v1/payments/:id` | bearer token | `PAYMENTS_INITIATE` | payment app and consent must match token |
| `GET /v1/webhook_deliveries` | client credentials | none | app deliveries only |
| `POST /v1/webhook_deliveries/:id/replay` | client credentials | none | delivery must belong to app |
| `PATCH /v1/scenarios/:code/activate` | client credentials | none | app scenario only |

## Operations Console

All `/ops` routes require an authenticated operator session backed by the Rails auth session model. They are intentionally separated from the public `/v1` API controllers so browser cookies, CSRF protection, and operational workflows do not leak into partner API behavior.

| Surface | Authentication | Scope rule |
| --- | --- | --- |
| `/ops` dashboard | operator session | aggregate sandbox health only |
| `/ops/consents` | operator session | inspect and revoke sandbox consents |
| `/ops/webhook_deliveries` | operator session | inspect and replay webhook deliveries |
| `/ops/scenarios` | operator session | activate/deactivate app-specific failure scenarios |
| `/ops/audit_events` | operator session | inspect immutable operational/API audit trail |
