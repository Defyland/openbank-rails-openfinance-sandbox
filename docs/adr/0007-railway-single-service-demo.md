# ADR 0007 - Railway Single-Service Demo Deployment

## Status

Accepted

## Context

OpenBank Sandbox already had a production-oriented Dockerfile, `PORT` support in
Puma, and explicit `/up` and `/ready` endpoints. What it lacked was a small,
public, config-as-code deploy surface for portfolio evaluation.

## Decision

Add `railway.json` and `RAILWAY_DEPLOY.md`, and document Railway as a
single-service demo topology that runs with `SOLID_QUEUE_IN_PUMA=true`.

## Consequences

Positive:

- the sandbox becomes publicly runnable with a lightweight deploy path;
- health and readiness are explicit for Railway activation and review;
- the repo gains a concrete demo surface without inventing a second container layout.

Negative:

- the demo topology is not the final multi-process production shape;
- queue work shares the web process in the Railway path;
- public hosting still does not imply FAPI/OIDC-grade controls.
