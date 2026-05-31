# Data Consistency

## Transaction Boundaries

Payment initiation is the main consistency-sensitive flow. `Sandbox::PaymentInitiator` creates or finds the idempotent payment inside a database transaction, applies ledger side effects for eligible payments, marks successful payments as `settled`, and persists webhook records before the transaction returns. Active Job enqueueing is configured to happen after transaction commit so workers do not race uncommitted primary records.

Consent revocation updates consent state and revokes active tokens in one method call. API tests cover revoked-token behavior through the resource endpoints.

## Idempotency

Payments use `developer_app_id + idempotency_key` as a unique key. A request fingerprint is calculated from canonical JSON. Reusing a key with the same payload returns the original payment, including when a concurrent insert wins the race after the pre-check. Reusing it with a different payload returns conflict.

## Indexes and Constraints

- foreign keys on all owned aggregates
- unique app client IDs
- unique consent external IDs per app
- unique bearer token digests
- unique payment idempotency keys per app
- unique webhook event IDs and idempotency keys
- check constraints for statuses, positive amounts, token lengths, and non-negative balances

## Isolation Assumptions

All partner-owned resources are scoped by developer app. All bank data reads are scoped by the consent customer. Tests exercise cross-customer and cross-app access attempts.

## Rollback Strategy

Migrations are additive and constraint-focused. For production rollout, deploy schema changes first, then code using the new fields. If a payment mutation fails inside its transaction, no webhook event should be persisted for that failed command.
