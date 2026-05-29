# Local Baseline

Date: 2026-05-29

Environment:

- Rails 8.1 hybrid monolith
- Ruby 3.3.6
- SQLite fallback adapter for local review
- Single local Rails server process
- Puma single process with 3 threads
- k6 executed through `grafana/k6` Docker image
- Host: local macOS development machine

Portfolio baseline target:

| Scenario | Target p95 | Error budget | Notes |
| --- | ---: | ---: | --- |
| Smoke | < 200 ms | 0% | Validates route, auth, and payment path. |
| Load | < 350 ms | < 1% | Normal partner QA traffic. |
| Stress | < 750 ms | < 5% | Confirms graceful degradation. |
| Spike | < 900 ms | < 5% | Confirms rate limiting and no crashes. |

Measured result:

| Scenario | p50 | p95 | p99 | Throughput | Error rate | Max RSS | Avg CPU |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Smoke | 20.19 ms | 33.14 ms | 35.17 ms | 5.30 req/s | 0.00% | n/a | n/a |
| Load | 110.20 ms | 179.08 ms | 254.29 ms | 72.86 req/s | 0.00% | 106.2 MB | 96.7% |
| Stress | 384.45 ms | 638.59 ms | 858.51 ms | 62.66 req/s | 0.00% | 109.6 MB | 96.7% |
| Spike | 375.31 ms | 560.18 ms | 689.43 ms | 112.27 req/s | 0.00% | 100.9 MB | 90.6% |

Raw k6 summaries are stored under `benchmarks/results/2026-05-29-*.json`. Process samples are stored in the matching `*-process.tsv` files.

Interpretation:

- All scenarios passed their p95 and error-rate thresholds.
- CPU is the local bottleneck under load and stress; RSS stayed stable under 110 MB.
- The stress test is close enough to the p95 target to be useful as a regression guard rather than a vanity benchmark.
