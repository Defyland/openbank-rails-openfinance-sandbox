# Consent Event Contract Drift

Use this runbook when partner webhooks or sandbox consumers reject consent or payment events.

## Triage

- Identify the event schema under `docs/events/`.
- Confirm consent status, permissions, developer app, and correlation ID are present.
- Verify revoked consents invalidate active tokens before resource access continues.
- Check webhook signature and delivery attempt history.

## Recovery

- Restore backward-compatible event fields.
- Replay signed webhook deliveries after the partner confirms compatibility.
- Do not bypass consent permission checks to work around a schema mismatch.
- Update scenario documentation if the drift came from scenario-specific behavior.
