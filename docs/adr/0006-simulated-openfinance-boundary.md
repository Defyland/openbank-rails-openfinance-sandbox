# ADR 0006: Separate Didactic Simulation from Production Open Finance Requirements

## Status

Accepted.

## Context

Open Finance production integrations require ecosystem-specific security, identity, directory, consent, conformance, and operational controls. In Brazil, the security profile is based on Financial-grade API concepts and references OAuth/OpenID Connect specifications such as FAPI, MTLS, JAR/PAR, PKCE, OpenID Connect, and Dynamic Client Registration. FAPI 2.0 also formalizes sender-constrained token usage and resource-server validation expectations for high-value APIs.

This repository is a partner testing sandbox. It is designed to help a partner team rehearse consent, token, resource access, payment, webhook, retry, and failure-scenario behavior. It is not a certified authorization server, resource server, bank participant, or Open Finance Brasil conformance implementation.

## Decision

Keep the simulation boundary explicit:

- Simulate client authentication with `X-Client-Id` and `X-Client-Secret`.
- Simulate OAuth token issuance with a consent-bound token endpoint.
- Simulate FAPI resource-server behavior by checking token validity, expiration, revocation, consent status, scopes, and app/customer isolation on every protected request.
- Simulate consent lifecycle through deterministic consent authorization, revocation, expiration, and audit events.
- Simulate partner webhook security through signed, persisted, replayable deliveries.
- Simulate reliability and negative paths through deterministic app-scoped scenarios and rate limits.

Do not implement certification-grade controls in this repository:

- mTLS-bound client authentication or certificate-bound access tokens.
- DPoP sender-constrained tokens.
- private_key_jwt, JWKS rotation, or Directory trust.
- Full authorization code flow, PAR, JAR, JARM, PKCE, nonce/acr handling, or user authentication ceremony.
- Dynamic Client Registration and OpenID Discovery metadata for certified participants.
- Official conformance suite execution or regulatory onboarding evidence.

## Consequences

- The project stays runnable and deterministic for partner testing.
- Security boundaries remain explicit in the domain model.
- Future production hardening can add mTLS, JWKS, PAR/JAR, and dynamic client registration without changing the core consent story.
- Interview/readme claims remain honest: the project demonstrates senior architectural thinking without pretending to be a regulated Open Finance implementation.
- Partner failure modes are still realistic: expired token, revoked consent, insufficient scope, cross-client access, signed webhook verification, idempotency conflict, and rate limiting.

## Production Upgrade Path

If this sandbox needed to become a production-grade Open Finance participant or certified simulator, the next architectural steps would be:

1. Replace header-based client credentials with standards-compliant OAuth/OIDC client authentication and certificate/key management.
2. Add Authorization Server metadata, JWKS, key rotation, signed request support, and a certified authorization flow.
3. Introduce sender-constrained tokens with mTLS or DPoP according to the target ecosystem profile.
4. Add PAR/JAR/JARM and user authentication/consent ceremonies where required.
5. Run official conformance tests and store evidence in release artifacts.
6. Replace HMAC-only webhook signing with ecosystem-approved message signing if required.
7. Add production incident, revocation, fraud, dispute, and regulatory reporting processes.

## References

- Open Finance Brasil Financial-grade API Security Profile v2.1.0: https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1334149240/EN+Open+Finance+Brasil+Financial-grade+API+Security+Profile+-+v2.1.0
- OpenID Foundation FAPI 2.0 Security Profile: https://openid.net/specs/fapi-security-profile-2_0.html
- OpenID Foundation FAPI Working Group specifications: https://openid.net/wg/fapi/specifications/
