# Threat Model

This threat model focuses on the sandbox boundary that matters most for partner testing: a partner client obtains consent-scoped authorization and then uses that authorization to access simulated financial resources. It intentionally models the same failure modes partners must handle in a real Open Finance integration, while keeping certification-grade controls out of scope for this repository.

## Assets

- Developer app credentials
- Consent state and permissions
- Bearer tokens
- Simulated customer account data
- Payment initiation commands
- Webhook signing material and delivery history

## Trust Boundaries

- Partner clients are outside the application trust boundary.
- Bearer tokens represent consent-scoped authorization, not app-wide access.
- Consent state is authoritative; cached token decisions must never override revoked or expired consent.
- Database state is trusted only through model validations and constraints.
- Webhook endpoints are untrusted and may fail or replay requests.
- `/v1` partner APIs and `/ops` browser workflows are separate controller boundaries with different authentication mechanisms.

## Key Threats and Controls

| Threat | Attack or failure mode | Control | Expected partner-visible behavior |
| --- | --- | --- | --- |
| Expired token | Partner reuses a bearer token after `expires_at`. | Token validation checks digest, status, expiration, consent status, and consent expiration together. | HTTP 401 with standardized error; partner must request a new token for an active consent. |
| Revoked consent | Customer/operator revokes consent but partner keeps using an old token. | `Consent#revoke!` revokes active tokens; resource reads require active consent. | HTTP 401/403 depending on validation point; partner must stop polling and recreate consent. |
| Insufficient scopes | Partner tries `PAYMENTS_INITIATE` with a token created from read-only consent. | `Security::Authorizer` checks permission per endpoint against the consent permission set. | HTTP 403 `forbidden`; partner must request a consent with the missing permission. |
| Cross-client access | Client A guesses a consent, payment, account, or webhook ID owned by Client B. | All lookups are scoped by authenticated `developer_app` and consent customer. | HTTP 404 for foreign resources or HTTP 403 for invalid authorization context. |
| Stolen client secret | Attacker obtains `X-Client-Secret`. | Secret is returned once and stored as digest. Rotation can be added without schema change. | Existing credentials can authenticate until rotated; operational response is credential rotation and audit review. |
| Stolen bearer token | Attacker obtains a bearer token. | Short TTL, digest storage, consent-scoped permissions, no query-string token support. | Blast radius is the consent permissions and token lifetime. Real FAPI production would require sender-constrained tokens. |
| Overbroad token permissions | Token grants more permissions than the consent. | Token permissions must be a subset of consent permissions. | Token issuance fails; resource APIs also enforce endpoint permissions. |
| Idempotency replay with changed payload | Partner or attacker reuses an idempotency key with different payment details. | Payment request fingerprint conflict returns HTTP 409. | Partner must use a new idempotency key or repeat the exact same request. |
| Signed webhook tampering | Intermediary changes webhook payload or replays modified body. | HMAC-SHA256 signature over timestamp plus canonical payload; event idempotency key persisted. | Partner should reject payloads whose computed signature does not match delivery signature. |
| Webhook replay | Same signed delivery arrives more than once. | Stable `event_id`, delivery idempotency key, and replay history. | Partner must deduplicate by `event_id` and treat events as at-least-once delivery. |
| Webhook SSRF | Tenant registers a webhook URL pointing to internal infrastructure. | Webhook delivery resolves the destination host before connecting and blocks private, loopback, link-local, multicast, documentation, and other non-public ranges by default. | Unsafe endpoints fail delivery and enter the normal retry/dead-letter path without exposing internal network access. |
| Rate limit abuse | Client floods token/resource/payment endpoints. | App/IP/token rate limiting with `Retry-After` response. | HTTP 429; partner must back off and retry after the advertised window. |
| Sensitive log exposure | Secrets, tokens, documents, or authorization headers appear in logs. | Rails parameter filtering for secrets, tokens, authorization, and documents. | Logs remain usable for support without leaking primary credentials. |
| Untraceable privileged action | Operator or partner action changes sensitive state without audit evidence. | Audit events persist actor, target, request ID, correlation ID, IP address, user agent, and metadata for sensitive API and operator workflows. | Incident review can reconstruct who did what and when. |

## Consent and OAuth/FAPI Simulation Notes

The sandbox simulates OAuth/FAPI concepts but does not claim certification coverage:

- Client authentication is represented by `X-Client-Id` and `X-Client-Secret`, not mTLS private_key_jwt, Dynamic Client Registration, or OpenID Directory integration.
- Token issuance uses a simplified client credentials-style endpoint bound to a consent ID, not a full authorization code, PAR/JAR, JARM, PKCE, or user authentication ceremony.
- Bearer tokens are consent-scoped and short-lived, but they are not sender-constrained through mTLS or DPoP.
- Resource servers reject expired/revoked tokens and insufficient permissions, matching the partner failure modes this sandbox is meant to exercise.
- Webhook signing is HMAC-based for deterministic local testing; production Open Finance message signing may require ecosystem-specific JOSE/JWS profiles.
- Webhook signing secrets are returned once and stored encrypted, but hosted deployments still need secret rotation and tenant-specific webhook allowlists.

## Residual Risk

The sandbox does not implement mTLS, JWKS, private_key_jwt, PAR/JAR, JARM, DPoP, certified OpenID Provider behavior, directory trust, or formal conformance tests. Those are roadmap items because the current product goal is deterministic partner workflow testing.

## Transversal architecture additions

- Token validation must always check client, consent, permission, status, and expiration together.
- Consent revocation is a security event and must invalidate active bearer tokens before downstream reads continue.
- Scenario engine behavior must never bypass tenant or permission checks.
- Webhook replay must preserve the original event identity and append delivery attempts rather than hiding failures.
- Full Open Finance certification controls are documented as out of scope for this sandbox slice.

## Primary References

- Open Finance Brasil Financial-grade API Security Profile v2.1.0: https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1334149240/EN+Open+Finance+Brasil+Financial-grade+API+Security+Profile+-+v2.1.0
- OpenID Foundation FAPI 2.0 Security Profile: https://openid.net/specs/fapi-security-profile-2_0.html
- OpenID Foundation FAPI Working Group specifications: https://openid.net/wg/fapi/specifications/
