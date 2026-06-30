# ADR 0008 - Publish the Repository Under the MIT License

## Status

Accepted

## Context

OpenBank Sandbox is already a public Rails sandbox with simulated Open Finance
flows, scenario toggles, Railway deployment guidance, and operational runbooks.
Without an explicit license, the repo is visible but not clearly reusable for
internal study or prototype work.

## Decision

Publish the repository under the MIT License and surface that choice in the
README.

## Consequences

Positive:

- The sandbox can be studied and adapted with a clear permissive license.
- The public product signal is now backed by an explicit reuse boundary.

Negative:

- Forks may copy the sandbox without preserving its scenario and deployment
  caveats.
- Third-party licenses remain governed by their own terms.
