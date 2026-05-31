# ADR 0003: Signed Webhook Outbox

## Status

Accepted

## Context

Partners need to test webhook signature verification, retries, replay, and delivery auditability. Payment and consent mutations must remain durable even when webhook delivery fails.

## Decision

Persist every outbound event as a `WebhookDelivery` record before delivery. Generate a one-time partner webhook signing secret at app registration, store it encrypted, and sign `signature_timestamp.canonical_json_body` with HMAC-SHA256. Process HTTP delivery attempts through Active Job and keep attempts, next retry time, last response status, last error, and terminal state.

## Consequences

- Mutations and event publication share a database transaction boundary.
- Failed webhooks can be inspected and replayed.
- Delivery uses an injectable HTTP adapter so tests are deterministic without external services while app environments can perform real outbound POSTs.
- Shared hosted environments still need egress controls and webhook URL allowlisting before exposing this to untrusted tenants.
