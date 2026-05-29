# ADR 0005: Solid Stack Operational Boundaries

## Status

Accepted

## Context

Rails 8 makes Solid Queue, Solid Cache, and Solid Cable a practical default for a small-to-medium monolith. The sandbox benefits from fewer external dependencies during review, local development, and single-server deployment. The risk is that database-backed infrastructure can become a bottleneck if traffic, fanout, or job volume grows without measurement.

## Decision

Keep Solid Queue, Solid Cache, and Solid Cable as the default production stack. Do not introduce Redis, Sidekiq, or Memcached until a measured operational signal justifies the extra dependency.

Migration triggers:

- Solid Queue: sustained queue latency above 60 seconds, more than 1,000 jobs/minute, or queue database write contention affecting API p95 latency.
- Solid Cache: cache table growth that requires frequent pruning, low hit rate with high write churn, or cache queries appearing in top database wait events.
- Solid Cable: sustained fanout beyond a single app node, more than 1,000 concurrent WebSocket clients, or cable database writes affecting request latency.
- Primary database impact: any Solid database workload that pushes API p95 beyond the documented SLO for two consecutive review windows.

## Consequences

Positive:

- Fewer moving parts for the portfolio and early production shape.
- One operational model for database backups, migrations, and local review.
- Rails-native defaults remain easy to explain and test.

Negative:

- The database layer carries more responsibility.
- Scale-out requires monitoring queue lag, cache churn, and cable fanout.
- A future migration must be planned deliberately instead of hidden behind premature abstraction.

## Follow-up

If a trigger is reached, migrate one subsystem at a time:

1. Move the most pressured subsystem first.
2. Keep behavior covered by the existing tests.
3. Add a benchmark before and after the migration.
4. Record the migration as a new ADR.
