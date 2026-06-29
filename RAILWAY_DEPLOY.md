# Railway Deploy

This guide configures OpenBank Sandbox as a single-service Railway deployment
for reviewer evaluation and public demo use.

## Runtime shape

- builder: `Dockerfile`
- activation health check: `/up`
- deeper readiness endpoint: `/ready`
- bootstrap: `bin/docker-entrypoint` runs `bin/prepare-runtime-databases`
- background jobs: `SOLID_QUEUE_IN_PUMA=true` for the single-service demo path

This path is deliberately simpler than a production multi-process topology. It
is meant to prove the API, ops console, consent lifecycle, and webhook sandbox
surface in one deployable service.

## Required variables

Set these in Railway:

```bash
RAILS_ENV=production
DATABASE_URL=${{Postgres.DATABASE_URL}}
RAILS_MASTER_KEY=<local config/master.key>
SOLID_QUEUE_IN_PUMA=true
OPERATOR_EMAIL=<ops-login-email>
OPERATOR_PASSWORD=<ops-login-password>
```

Useful optional variables:

```bash
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=<collector-endpoint>
OPENBANK_WEBHOOK_DELIVERY_ADAPTER=http
```

## Suggested flow

```bash
railway login
railway init --name openbank-rails-openfinance-sandbox
railway add --database postgres
railway up
railway domain
```

## Five-minute verification

After deploy:

```bash
railway status
railway logs
curl -fsS "$RAILWAY_PUBLIC_DOMAIN/up"
curl -fsS "$RAILWAY_PUBLIC_DOMAIN/ready"
```

Then sign in to `/ops` with the configured operator account and exercise one
consent flow plus one payment/webhook flow from the API examples in the README.

## Limits

- This is a demo topology, not a final production topology.
- The single web service also supervises Solid Queue work.
- Real Open Finance controls such as mTLS, JWKS, and shared-hosted webhook
  allowlists remain out of scope for this deployment path.
