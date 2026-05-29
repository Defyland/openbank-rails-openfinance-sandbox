# ADR 0006: Simulate Open Finance Security Boundaries Before Certification Scope

## Status

Accepted.

## Context

Open Finance production integrations include mTLS, FAPI profiles, JWKS, PAR/JAR, consent rules, and conformance requirements. This repository is a partner sandbox, not a certified bank participant.

## Decision

The MVP simulates OAuth/FAPI concepts through client credentials, bearer tokens, consent-scoped permissions, signed webhooks, scenarios, audit logs, and rate limiting. Certification-specific controls are documented but not implemented as production-grade security infrastructure.

## Consequences

- The project stays runnable and deterministic for partner testing.
- Security boundaries remain explicit in the domain model.
- Future production hardening can add mTLS, JWKS, PAR/JAR, and dynamic client registration without changing the core consent story.
