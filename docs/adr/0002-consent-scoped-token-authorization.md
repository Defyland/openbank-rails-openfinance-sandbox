# ADR 0002: Consent-Scoped Token Authorization

## Status

Accepted

## Context

Open Finance access is consent-driven. A partner app must not read accounts or initiate payments unless a customer consent grants the exact permission and remains active.

## Decision

Issue short-lived bearer tokens only from authorized consents. Store token digests, not raw tokens. Copy the consent permission set into the token at issuance and enforce endpoint-specific permissions on every protected endpoint.

## Consequences

- Revoked or expired consents immediately make tokens unusable.
- Account and payment lookups are scoped by both developer app and consent customer.
- Permission failures are deterministic and testable.
- The sandbox does not implement full FAPI/OIDC yet; it simulates the resource-server authorization model that partner teams need for integration testing.
