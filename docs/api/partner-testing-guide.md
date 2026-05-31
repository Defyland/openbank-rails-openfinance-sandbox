# Partner Testing Guide

This guide describes how partner teams should use OpenBank Sandbox to rehearse consent, simulated OAuth/FAPI, resource access, payments, webhooks, and negative paths.

## Testing Goals

The sandbox is designed to validate partner behavior around:

- consent creation, authorization, expiration, and revocation
- consent-scoped token issuance
- permission failures for insufficient scopes
- cross-client and cross-customer isolation
- idempotent payment initiation
- signed webhook verification and deduplication
- rate limit backoff and retry behavior
- deterministic failure scenarios

It is not a certified Open Finance authorization server or production bank participant.

## Happy Path

1. Register a developer app and persist the returned `client_id`, one-time `client_secret`, and one-time `webhook_signing_secret`.
2. Create a consent with the smallest permission set needed for the test.
3. Authorize the consent.
4. Issue a consent-scoped bearer token through `/v1/oauth/token`.
5. Call account, balance, transaction, and payment APIs with the bearer token.
6. Receive signed webhook deliveries and deduplicate by `event_id`.
7. Revoke the consent and verify old tokens stop working.

## Simulated OAuth/FAPI Contract

| Production concept | Sandbox representation | Partner behavior being tested |
| --- | --- | --- |
| OAuth client authentication | `X-Client-Id` and `X-Client-Secret` headers | Store and rotate client credentials safely. |
| Authorization grant | Consent-bound `/v1/oauth/token` call | Request tokens only for active consent. |
| Access token | Short-lived bearer token stored as digest | Send token only in `Authorization` header. |
| Resource server scope check | Endpoint-level permission enforcement | Handle HTTP 403 and request correct consent permissions. |
| Consent revocation | `PATCH /v1/consents/:id/revoke` or operator action | Stop using tokens and scheduled polling immediately. |
| FAPI sender-constrained tokens | Not implemented | Understand that real production would require mTLS or DPoP. |
| PAR/JAR/JARM | Not implemented | Understand that real production would have signed pushed authorization requests and stronger front-channel protections. |

## Negative Test Matrix

| Scenario | How to trigger | Expected result |
| --- | --- | --- |
| Expired token | Use a token after `expires_at` or force expired fixture in tests. | HTTP 401; issue a new token only if consent remains active. |
| Revoked consent | Revoke consent, then call `/v1/accounts` with the old token. | HTTP 401/403; partner stops access for that consent. |
| Insufficient scopes | Create consent without `PAYMENTS_INITIATE`, then call `POST /v1/payments`. | HTTP 403; partner requests a new consent with payment permission. |
| Cross-client access | Client B tries to read Client A consent/payment/webhook ID. | HTTP 404 or HTTP 403; partner must not infer foreign resources. |
| Idempotency conflict | Reuse `Idempotency-Key` with a different payment body. | HTTP 409; partner uses a new key for a new business instruction. |
| Signed webhook tampering | Modify webhook body before signature verification. | Partner rejects the delivery. |
| Webhook replay | Replay the same delivery from `/ops` or `/v1/webhook_deliveries/:id/replay`. | Partner deduplicates by `event_id`. |
| Rate limit | Send requests above `rate_limit_per_minute`. | HTTP 429 with retry guidance. |

## Event Expectations

Partners should build receivers against the v1 contracts in `docs/events/`:

- `consent.authorized`
- `consent.revoked`
- `payment.created`
- `payment.settled`
- `payment.rejected`

The receiver should verify `X-OpenBank-Signature` by computing HMAC-SHA256 with the `webhook_signing_secret` over `X-OpenBank-Signature-Timestamp + "." + canonical_json_body`.

The receiver should persist:

- raw request body
- computed signature and received signature
- signature timestamp
- `event_id`
- `event_type`
- `schema_version`
- `correlation_id`
- processing result

## Production Gap Awareness

When moving from this sandbox to a real Open Finance ecosystem, partners should expect additional requirements:

- mTLS or DPoP sender-constrained tokens
- JWKS and key rotation
- private_key_jwt or ecosystem-specific client authentication
- PAR/JAR/JARM
- certified OpenID Provider metadata and conformance tests
- stronger non-repudiation and ecosystem-specific message signatures
- formal incident, revocation, fraud, dispute, and reporting processes

The sandbox intentionally makes these gaps explicit so partner teams do not confuse deterministic QA coverage with regulatory production readiness.
