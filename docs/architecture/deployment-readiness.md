# Deployment Readiness

OpenBank Sandbox needs a Rails API, operator surface, PostgreSQL, Solid Queue, cache, and webhook delivery workers.

## Current posture

- Rails API and operations UI.
- PostgreSQL-backed data, queues, cache, cable, and sessions.
- Health, readiness, metrics, OpenTelemetry hooks, and Grafana dashboard.
- Signed outbound webhooks with retry, response status capture, and dead-letter state.

## Deferred platform work

- Kubernetes and Helm are deferred until sandbox scenarios, queue ownership, and webhook retry policy stabilize.
- Real Open Finance production controls such as mTLS and JWKS are deferred because this project is a simulator.
- Managed secrets and token key rotation should be added before any public shared sandbox deployment.
- Webhook delivery blocks private-network destinations by default. Tenant-specific webhook URL allowlists should still be added before exposing a shared hosted sandbox.
