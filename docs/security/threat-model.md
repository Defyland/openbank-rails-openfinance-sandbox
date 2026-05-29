# Threat Model

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
- Database state is trusted only through model validations and constraints.
- Webhook endpoints are untrusted and may fail or replay requests.

## Key Threats and Controls

| Threat | Control |
| --- | --- |
| Stolen client secret | Secret is returned once and stored as digest. Rotation can be added without schema change. |
| Stolen bearer token | Short TTL, digest storage, revocation through consent lifecycle. |
| Broken object level authorization | Every account/payment lookup checks developer app and consent customer scope. |
| Overbroad token permissions | Token permissions must be a subset of consent permissions. |
| Idempotency replay with changed payload | Request fingerprint conflict returns HTTP 409. |
| Webhook tampering | HMAC-SHA256 signature over canonical payload. |
| Noisy or abusive client | App/IP/token rate limiting with Retry-After response. |
| Sensitive log exposure | Rails parameter filtering for secrets, tokens, authorization, and documents. |
| Untraceable privileged action | Audit events persist actor, target, request ID, correlation ID, IP address, user agent, and metadata for sensitive API and operator workflows. |

## Residual Risk

The sandbox does not yet implement mTLS, JWKS, PAR/JAR, or full FAPI profiles. Those are roadmap items because the current product goal is deterministic partner workflow testing.

## Transversal architecture additions

- Token validation must always check client, consent, permission, status, and expiration together.
- Consent revocation is a security event and must invalidate active bearer tokens before downstream reads continue.
- Scenario engine behavior must never bypass tenant or permission checks.
- Webhook replay must preserve the original event identity and append delivery attempts rather than hiding failures.
- Full Open Finance certification controls are documented as out of scope for this sandbox slice.
