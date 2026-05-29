# ADR 0003: Signed Webhook Outbox

## Status

Accepted

## Context

Partners need to test webhook signature verification, retries, replay, and delivery auditability. Payment and consent mutations must remain durable even when webhook delivery fails.

## Decision

Persist every outbound event as a `WebhookDelivery` record before delivery. Sign canonical JSON payloads with HMAC-SHA256 derived from the developer app credential digest and Rails secret key base. Process delivery attempts through Active Job and keep attempts, next retry time, last error, and terminal state.

## Consequences

- Mutations and event publication share a database transaction boundary.
- Failed webhooks can be inspected and replayed.
- Delivery is deterministic in tests and scenario-driven in sandbox usage.
- A production HTTP delivery adapter can be added later without changing the API contract or event table.
