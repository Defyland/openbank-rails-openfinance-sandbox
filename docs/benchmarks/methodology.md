# Benchmark Methodology

Benchmarks use k6 and target the partner-critical path:

1. liveness and readiness
2. developer app creation
3. consent creation and authorization
4. token issuance
5. account, balance, and transaction reads
6. idempotent payment initiation

## Scenarios

- Smoke: one virtual user confirms onboarding and token issuance work end to end.
- Load: steady traffic for a pre-authenticated partner session.
- Stress: higher concurrency for pre-authenticated read and payment traffic.
- Spike: sudden read-heavy traffic increase for a pre-authenticated partner session.

The load, stress, and spike scripts bootstrap a partner app once in `setup()` and set a high benchmark-only app rate limit through `RATE_LIMIT_PER_MINUTE`. That keeps the benchmark focused on API throughput and latency. Rate limiting itself is covered by the functional test suite and should be benchmarked separately when tuning abuse controls.

## Metrics to Capture

- p50, p95, p99 latency
- throughput
- HTTP error rate
- payment conflict/error rate
- process RSS and CPU notes when run locally
- database adapter and machine profile

## Command Pattern

```bash
DATABASE_ADAPTER=sqlite3 ruby bin/rails server
k6 run --summary-trend-stats "avg,min,med,max,p(90),p(95),p(99)" benchmarks/smoke.js
k6 run --summary-trend-stats "avg,min,med,max,p(90),p(95),p(99)" benchmarks/load.js
k6 run --summary-trend-stats "avg,min,med,max,p(90),p(95),p(99)" benchmarks/stress.js
k6 run --summary-trend-stats "avg,min,med,max,p(90),p(95),p(99)" benchmarks/spike.js
```
