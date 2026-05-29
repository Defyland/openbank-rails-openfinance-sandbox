require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  test "signs canonical payload and marks successful delivery" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "consent.authorized",
      aggregate_type: "Consent",
      aggregate_id: 123,
      payload: { "status" => "authorized", "consent_id" => "cns_1" }
    )

    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", app.webhook_signing_secret, delivery.canonical_payload)
    assert_equal expected_signature, delivery.signature

    delivery.deliver!

    assert_equal "delivered", delivery.status
    assert_equal 1, delivery.attempts_count
    assert_not_nil delivery.delivered_at
  end

  test "webhook retry scenario fails and schedules next attempt" do
    app, = create_developer_app
    app.update!(active_scenario_code: "webhook_retry")
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.accepted",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "accepted" }
    )

    delivery.deliver!

    assert_equal "failed", delivery.status
    assert_equal 1, delivery.attempts_count
    assert_not_nil delivery.next_attempt_at
  end

  test "canonical payload is stable for nested hashes" do
    app, = create_developer_app
    first_delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.accepted",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 123,
      payload: {
        "event_type" => "payment.accepted",
        "payment" => { "status" => "accepted", "amount_cents" => 9_900 },
        "meta" => { "branch" => "0001", "account" => "12345-6" }
      }
    )
    second_delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.accepted",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 124,
      payload: {
        "meta" => { "account" => "12345-6", "branch" => "0001" },
        "payment" => { "amount_cents" => 9_900, "status" => "accepted" },
        "event_type" => "payment.accepted"
      }
    )

    assert_equal first_delivery.canonical_payload, second_delivery.canonical_payload
    assert_equal first_delivery.signature, second_delivery.signature
  end
end
