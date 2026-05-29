# Benchmark Baseline

The committed k6 scripts exercise the full partner workflow against a local Rails server.

Run order:

1. `k6 run benchmarks/smoke.js`
2. `k6 run benchmarks/load.js`
3. `k6 run benchmarks/stress.js`
4. `k6 run benchmarks/spike.js`

The expected baseline and method are documented in `docs/benchmarks/`.

The current measured baseline is in `docs/benchmarks/local-baseline.md`, with raw k6 output under `benchmarks/results/`.
