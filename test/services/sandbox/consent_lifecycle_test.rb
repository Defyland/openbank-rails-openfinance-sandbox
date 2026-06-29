require "test_helper"

module Sandbox
  class ConsentLifecycleTest < ActiveSupport::TestCase
    test "authorization rolls back when webhook enqueue fails" do
      customer, = create_customer_with_account
      app, = create_developer_app
      consent = Consent.create!(
        developer_app: app,
        sandbox_customer: customer,
        permissions: DEFAULT_PERMISSIONS,
        expires_at: 30.days.from_now
      )
      original_enqueue = WebhookDelivery.method(:enqueue!)

      WebhookDelivery.define_singleton_method(:enqueue!) { |**| raise "webhook unavailable" }

      assert_raises(RuntimeError) do
        Sandbox::ConsentLifecycle.authorize!(
          consent: consent,
          actor: app,
          audit_action: "v1.consent.authorized",
          correlation_id: "corr-consent-authorize-rollback"
        )
      end

      assert_equal "awaiting_authorization", consent.reload.status
      assert_nil consent.authorized_at
      assert_equal 0, AuditEvent.where(action: "v1.consent.authorized", target: consent).count
      assert_equal 0, WebhookDelivery.where(event_type: "consent.authorized", aggregate_type: "Consent", aggregate_id: consent.id).count
    ensure
      WebhookDelivery.define_singleton_method(:enqueue!) do |**kwargs|
        original_enqueue.call(**kwargs)
      end
    end

    test "revocation rolls back token revocation and audit evidence when webhook enqueue fails" do
      customer, = create_customer_with_account
      app, = create_developer_app
      consent = create_authorized_consent(app: app, customer: customer)
      token = issue_token(app: app, consent: consent)
      original_enqueue = WebhookDelivery.method(:enqueue!)

      WebhookDelivery.define_singleton_method(:enqueue!) { |**| raise "webhook unavailable" }

      assert_raises(RuntimeError) do
        Sandbox::ConsentLifecycle.revoke!(
          consent: consent,
          actor: app,
          audit_action: "v1.consent.revoked",
          correlation_id: "corr-consent-revoke-rollback",
          revocation_reason: "partner_request"
        )
      end

      assert_equal "authorized", consent.reload.status
      assert_nil consent.revoked_at
      assert_nil token.reload.revoked_at
      assert token.active?
      assert_equal 0, AuditEvent.where(action: "v1.consent.revoked", target: consent).count
      assert_equal 0, WebhookDelivery.where(event_type: "consent.revoked", aggregate_type: "Consent", aggregate_id: consent.id).count
    ensure
      WebhookDelivery.define_singleton_method(:enqueue!) do |**kwargs|
        original_enqueue.call(**kwargs)
      end
    end
  end
end
