# Production Readiness Caveats

This document explains the remaining production caveats, what was resolved in this repository, why some items are intentionally not fully implemented, and how to proceed when the sandbox needs to run as a real hosted service.

## Summary

| Concern | What is resolved now | Why not fully implemented here | How to proceed when needed |
| --- | --- | --- | --- |
| Managed SMTP | Production mailer reads SMTP settings from environment variables. | No real sender domain, provider account, DNS records, or delivery SLA exists in a portfolio repo. | Pick SES/Postmark/SendGrid/etc., configure SPF/DKIM/DMARC, store SMTP secrets in Kamal secrets, and run delivery smoke tests. |
| Managed file storage | Active Storage can switch from local disk to S3-compatible storage with `ACTIVE_STORAGE_SERVICE=amazon`. | The product does not yet expose partner-facing attachments, and bucket/IAM choices are infrastructure-specific. | Create a private encrypted bucket, use least-privilege IAM, configure lifecycle rules, and migrate blobs before multi-node deploys. |
| PostgreSQL backup/restore | `bin/backup-postgres`, `bin/restore-postgres`, and a restore runbook are included. | Managed snapshots/PITR require a real cloud database and operational ownership. | Enable managed PITR, schedule portable dumps, store them off-host, and run quarterly restore drills. |
| APM/exporter credentials | OpenTelemetry instrumentation and OTLP env hooks are present. | Vendor credentials and sampling policy depend on the target account and cost envelope. | Choose an APM backend, set OTLP endpoint/headers, define sampling, and add dashboards tied to SLOs. |
| SLO ownership | Initial Prometheus alerts and a documented SLO starting point are included. | Real SLOs require traffic patterns, on-call ownership, and business impact decisions. | Assign owner, set burn-rate alerts, review incidents, and adjust objectives using production data. |
| Solid Queue/Cache/Cable scale limits | The Solid stack is documented as the default, with migration triggers in ADR 0005. | Adding Redis/Sidekiq/Memcached now would increase moving parts without measured need. | Move one component at a time only after queue lag, cache pressure, cable fanout, or DB contention crosses documented thresholds. |

## What Can Be Resolved in the Repo

Resolved now:

- SMTP configuration is environment-driven in production.
- S3-compatible Active Storage is configured and dependency-backed.
- Portable PostgreSQL backup and restore scripts are versioned.
- Prometheus alert rules are versioned and mounted by Docker Compose.
- Production caveats are documented with concrete next steps.

Not resolved here by design:

- Real SMTP account and verified sender domain.
- Real S3 bucket, IAM policy, encryption policy, and retention rules.
- Managed PostgreSQL PITR and restore drill evidence.
- Real APM account, API key, sampling policy, and alert destinations.
- Human on-call ownership and incident process.

Those require external infrastructure and organizational decisions rather than Rails code.

## Operational Checklist Before a Real Launch

1. Set `APP_HOST`, SMTP variables, and Kamal secrets.
2. Set `ACTIVE_STORAGE_SERVICE=amazon` and S3-compatible storage variables if attachments are used outside a single node.
3. Enable managed PostgreSQL backups/PITR and run the restore drill in `docs/runbooks/postgres-backup-restore.md`.
4. Set `OTEL_ENABLED=true`, `OTEL_EXPORTER_OTLP_ENDPOINT`, and provider headers.
5. Load `ops/prometheus/alerts.yml` in the monitoring stack and connect Alertmanager routes.
6. Review ADR 0005 before adding Redis, Sidekiq, or a separate cache tier.
