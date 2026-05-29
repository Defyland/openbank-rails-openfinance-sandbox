# OpenBank Sandbox Event Contracts

OpenBank Sandbox emits events for consent and payment lifecycle changes and uses signed webhook deliveries for partner-facing notifications.

## Envelope

Every event must include:

- `event_id`
- `event_type`
- `schema_version`
- `occurred_at`
- `producer`
- `developer_app_id`
- `consent_id` when applicable
- `payment_id` when applicable
- `correlation_id`
- `payload`

## Compatibility policy

- Consumers deduplicate by `event_id`.
- Consent revocation events must be processed even if token caches are stale.
- Payment initiation events must preserve idempotency and `correlation_id`.
- Webhook signatures cover the canonical event body and timestamp.

## Versioned schemas

- [consent.authorized.v1.json](consent.authorized.v1.json)
- [consent.revoked.v1.json](consent.revoked.v1.json)
- [payment.created.v1.json](payment.created.v1.json)
- [payment.settled.v1.json](payment.settled.v1.json)
- [payment.rejected.v1.json](payment.rejected.v1.json)
