require "test_helper"

class RepositorySpecComplianceTest < ActiveSupport::TestCase
  REQUIRED_PATHS = %w[
    README.md
    openapi.yaml
    Dockerfile
    docker-compose.yml
    .github/workflows/ci.yml
    docs/adr/0001-rails-api-postgres-first.md
    docs/adr/0002-consent-scoped-token-authorization.md
    docs/adr/0003-signed-webhook-outbox.md
    docs/adr/0004-hybrid-hotwire-operations-ui.md
    docs/adr/0005-solid-stack-operational-boundaries.md
    docs/implementation/hybrid-rails-stack-plan.md
    docs/api/http-examples.md
    docs/api/error-format.md
    docs/architecture/overview.md
    docs/architecture/data-consistency.md
    docs/security/threat-model.md
    docs/security/authorization-matrix.md
    docs/benchmarks/methodology.md
    docs/benchmarks/local-baseline.md
    docs/runbooks/common-issues.md
    docs/runbooks/operations-console.md
    docs/runbooks/postgres-backup-restore.md
    docs/runbooks/production-readiness.md
    docs/scenarios/catalog.md
    observability/grafana/openbank-sandbox-overview.json
    ops/prometheus/alerts.yml
    benchmarks/baseline.md
    benchmarks/smoke.js
    benchmarks/load.js
    benchmarks/stress.js
    benchmarks/spike.js
  ].freeze

  test "repository includes mandatory portfolio evidence" do
    missing = REQUIRED_PATHS.reject { |path| Rails.root.join(path).exist? }

    assert_empty missing, "Missing required project evidence: #{missing.join(', ')}"
  end

  test "README keeps required initiative sections" do
    readme = Rails.root.join("README.md").read
    required_headings = [
      "What is this product?",
      "Problem it solves",
      "Target users",
      "Main features",
      "Architecture overview",
      "Tech stack",
      "Domain model",
      "API documentation",
      "Async or event architecture",
      "Database design",
      "Testing strategy",
      "Performance benchmarks",
      "Observability",
      "Security considerations",
      "Trade-offs and decisions",
      "How to run locally",
      "How to run tests",
      "Failure scenarios",
      "Roadmap"
    ]

    missing = required_headings.reject { |heading| readme.include?(heading) }

    assert_empty missing, "README missing required sections: #{missing.join(', ')}"
  end
end
