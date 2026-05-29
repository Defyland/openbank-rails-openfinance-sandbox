require "test_helper"

class AuditTrailTest < ActiveSupport::TestCase
  test "records a persisted audit event with current request context" do
    Current.request_id = "req-audit-test"
    Current.correlation_id = "corr-audit-test"
    Current.ip_address = "127.0.0.1"
    Current.user_agent = "Minitest"

    event = AuditTrail.record!(
      action: "ops.consent.revoked",
      actor: users(:operator),
      target: consents(:authorized),
      metadata: { reason: "manual review" }
    )

    assert_predicate event, :persisted?
    assert_equal "ops.consent.revoked", event.action
    assert_equal "ops@example.test", event.actor_identifier
    assert_equal consents(:authorized).external_id, event.target_identifier
    assert_equal "req-audit-test", event.request_id
    assert_equal "corr-audit-test", event.correlation_id
    assert_equal({ "reason" => "manual review" }, event.metadata)
  ensure
    Current.reset
  end
end
