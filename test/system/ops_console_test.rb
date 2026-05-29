require "application_system_test_case"

class OpsConsoleTest < ApplicationSystemTestCase
  test "operator signs in and sees the control plane" do
    visit ops_root_path

    assert_text "OpenBank Sandbox"

    fill_in "Email", with: users(:operator).email_address
    fill_in "Password", with: "password-12345"
    click_on "Sign in"

    assert_text "Sandbox control plane"
    assert_text "Recent payments"
    assert_text "Recent audit trail"
    assert_equal "ops.session.created", AuditEvent.order(created_at: :desc).first.action
  end

  test "operator activates a failure scenario for a partner app" do
    app = developer_apps(:partner)

    sign_in_as_operator
    visit ops_scenarios_path

    within %(form[action="#{activate_ops_scenario_path('payment_rejected')}"]) do
      select app.name, from: "developer_app_id"
      click_on "Activate payment_rejected"
    end

    assert_text "payment_rejected activated for #{app.name}."
    assert_equal "payment_rejected", app.reload.active_scenario_code
    assert_equal "ops.scenario.activated", AuditEvent.order(created_at: :desc).first.action
  end

  test "operator revokes a consent from the console" do
    consent = consents(:authorized)

    sign_in_as_operator
    visit ops_consent_path(consent)
    click_on "Revoke"

    assert_text "Consent revoked."
    assert_equal "revoked", consent.reload.status
    assert_equal "ops.consent.revoked", AuditEvent.order(created_at: :desc).first.action
  end

  test "operator replays a failed webhook delivery" do
    delivery = webhook_deliveries(:failed_payment)

    sign_in_as_operator
    visit ops_webhook_delivery_path(delivery)
    click_on "Replay"

    assert_text "Webhook replay enqueued."
    assert_equal "pending", delivery.reload.status
    click_on "Audit"
    assert_text "ops.webhook_delivery.replayed"
  end
end
