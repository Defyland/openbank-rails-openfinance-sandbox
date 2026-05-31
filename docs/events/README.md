# OpenBank Sandbox Event Contracts

OpenBank Sandbox documents versioned events for consent and payment lifecycle changes and uses signed webhook deliveries for partner-facing notifications. These contracts are intentionally stable enough for partner QA automation while remaining clear about their sandbox scope.

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

The envelope is shared across events so partners can build one receiver pipeline and route by `event_type` plus `schema_version`.

## Compatibility policy

- Consumers deduplicate by `event_id`.
- Delivery is at-least-once; repeated webhook deliveries are valid and must not create duplicate partner-side effects.
- Consumers must reject events with unsupported `schema_version`.
- Consent revocation events must be processed even if token caches are stale.
- Payment initiation events must preserve idempotency and `correlation_id`.
- Webhook signatures cover the canonical event body and timestamp.
- New optional payload fields may be added in a future minor-compatible revision; removed or semantically changed fields require a new schema version.

## Versioned schemas

- [consent.authorized.v1.json](consent.authorized.v1.json)
- [consent.revoked.v1.json](consent.revoked.v1.json)
- [payment.created.v1.json](payment.created.v1.json)
- [payment.settled.v1.json](payment.settled.v1.json)
- [payment.rejected.v1.json](payment.rejected.v1.json)

## Event Semantics

| Event | When it is emitted | Partner action |
| --- | --- | --- |
| `consent.authorized` | A consent moves from `awaiting_authorization` to `authorized`. | Cache consent permissions and begin token/resource tests. |
| `consent.revoked` | An authorized consent is revoked by API, operator action, or policy simulation. | Stop using tokens tied to the consent and remove scheduled polling. |
| `payment.created` | A payment request is persisted in the sandbox command model. | Correlate the payment by `payment_id`, `idempotency_key`, and `external_reference`. |
| `payment.settled` | The sandbox applies the payment effect to the simulated ledger. | Mark the partner-side payment as completed. |
| `payment.rejected` | The payment is rejected by deterministic scenario or validation/funds failure. | Surface `failure_code` and avoid retrying without a changed business instruction. |

## Signature Verification Contract

Sandbox webhook deliveries are signed with HMAC-SHA256 over `signature_timestamp.canonical_json_body`. The timestamp is sent in `X-OpenBank-Signature-Timestamp`, and the hex digest is sent in `X-OpenBank-Signature`.

Partner receivers should:

1. Rebuild the canonical JSON body using deterministic key ordering.
2. Compute HMAC-SHA256 with the app webhook signing secret over `timestamp + "." + canonical_body`.
3. Compare with the delivery signature using constant-time comparison.
4. Deduplicate by `event_id`.
5. Persist the raw body, signature, and `correlation_id` for support.

## Sandbox Naming Note

The application code currently persists delivery records for concrete processing outcomes. The documented v1 contracts define the stable partner-facing vocabulary for QA automation: creation, settlement, and rejection. If implementation event names change, the compatibility rule is to keep these v1 schemas stable or publish v2.
