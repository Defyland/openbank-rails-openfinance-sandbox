# PostgreSQL Backup and Restore

This runbook covers application-owned PostgreSQL backups for environments where the platform team also uses managed database snapshots or point-in-time recovery.

## Scope

- Primary database: mandatory backup target. It contains developer apps, consents, accounts, payments, webhook delivery history, users, sessions, and audit events.
- Solid Queue database: optional backup target for zero-loss job recovery. In this sandbox, jobs are derivative of primary records, so webhook work can also be replayed from persisted deliveries.
- Solid Cache and Solid Cable databases: not disaster-recovery critical. They can be rebuilt after restore.

## Create a Backup

```bash
DATABASE_URL=postgres://user:pass@host:5432/openbank_sandbox_production \
BACKUP_DIR=backups/postgres \
bin/backup-postgres
```

The script creates a PostgreSQL custom-format dump and a SHA-256 checksum when checksum tooling is available.

Use `BACKUP_DATABASE_URL` to back up a non-primary database:

```bash
BACKUP_DATABASE_URL=postgres://user:pass@host:5432/openbank_sandbox_production_queue \
BACKUP_DIR=backups/postgres/queue \
bin/backup-postgres
```

## Restore

Never restore into production without an incident owner, a maintenance window, and a rollback decision recorded.

```bash
DATABASE_URL=postgres://user:pass@host:5432/openbank_sandbox_restore \
BACKUP_FILE=backups/postgres/openbank-sandbox-20260529T180000Z.dump \
CONFIRM_RESTORE=true \
bin/restore-postgres
```

After restore:

```bash
bin/rails db:migrate
bin/rails runner 'puts({ apps: DeveloperApp.count, consents: Consent.count, payments: PaymentInitiation.count, audit_events: AuditEvent.count }.inspect)'
bin/rails runner 'puts WebhookDelivery.where(status: "pending").count'
```

## Production Policy

- Managed PostgreSQL snapshots/PITR remain the first line of defense.
- `bin/backup-postgres` is the application-level portable backup path.
- Store dumps outside the app host, encrypted at rest, with retention defined by business requirements.
- Run a restore drill before launch and at least once per quarter after launch.
- Define RPO/RTO per environment. A reasonable starting point for this sandbox is RPO 15 minutes and RTO 60 minutes for production demos.
