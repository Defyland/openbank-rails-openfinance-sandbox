require "test_helper"

class OpsConsentManagementTest < ActionDispatch::IntegrationTest
  test "operator revokes a consent from the ops console" do
    consent = consents(:authorized)

    post "/session", params: {
      email_address: users(:operator).email_address,
      password: "password-12345"
    }

    assert_response :redirect

    patch "/ops/consents/#{consent.id}/revoke"

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Consent revoked."
    assert_equal "revoked", consent.reload.status
    assert_equal "ops.consent.revoked", AuditEvent.order(created_at: :desc).first.action
  end
end
