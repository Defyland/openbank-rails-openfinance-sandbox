require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  test "signs canonical payload with timestamp and marks successful http delivery" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "consent.authorized",
      aggregate_type: "Consent",
      aggregate_id: 123,
      payload: { "status" => "authorized", "consent_id" => "cns_1" }
    )
    http_client = Class.new do
      class << self
        attr_accessor :requests
      end
      self.requests = []

      def self.deliver!(delivery)
        requests << {
          url: delivery.developer_app.webhook_url,
          body: delivery.canonical_payload,
          headers: delivery.delivery_headers
        }
        Sandbox::WebhookHttpClient::Response.new(202, "accepted")
      end
    end

    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      app.webhook_signing_secret,
      "#{delivery.signature_timestamp.iso8601}.#{delivery.canonical_payload}"
    )
    assert_equal expected_signature, delivery.signature

    delivery.deliver!(http_client: http_client)

    assert_equal "delivered", delivery.status
    assert_equal 1, delivery.attempts_count
    assert_not_nil delivery.delivered_at
    request = http_client.requests.fetch(0)
    assert_equal app.webhook_url, request.fetch(:url)
    assert_equal delivery.canonical_payload, request.fetch(:body)
    assert_equal delivery.event_id, request.dig(:headers, "X-OpenBank-Event-ID")
    assert_equal delivery.event_type, request.dig(:headers, "X-OpenBank-Event-Type")
    assert_equal delivery.signature, request.dig(:headers, "X-OpenBank-Signature")
    assert_equal delivery.signature_timestamp.iso8601, request.dig(:headers, "X-OpenBank-Signature-Timestamp")
  end

  test "webhook retry scenario fails and schedules next attempt" do
    app, = create_developer_app
    app.update!(active_scenario_code: "webhook_retry")
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "settled" }
    )

    delivery.deliver!

    assert_equal "failed", delivery.status
    assert_equal 1, delivery.attempts_count
    assert_not_nil delivery.next_attempt_at
    assert_enqueued_jobs 1, only: WebhookDeliveryJob
  end

  test "webhook url text does not force delivery failure outside explicit scenarios" do
    app, = create_developer_app(webhook_url: "https://fail.example.test/webhooks")
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "settled" }
    )
    http_client = Class.new do
      def self.deliver!(_delivery)
        Sandbox::WebhookHttpClient::Response.new(202, "accepted")
      end
    end

    delivery.deliver!(http_client: http_client)

    assert_equal "delivered", delivery.status
    assert_nil delivery.last_error
  end

  test "http delivery failure schedules retry and records response status" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "settled" }
    )
    http_client = Class.new do
      def self.deliver!(_delivery)
        Sandbox::WebhookHttpClient::Response.new(503, "unavailable")
      end
    end

    assert_enqueued_with(job: WebhookDeliveryJob, args: [ delivery.id ]) do
      delivery.deliver!(http_client: http_client)
    end

    assert_equal "failed", delivery.status
    assert_equal 503, delivery.last_response_status
    assert_match "HTTP 503", delivery.last_error
    assert_not_nil delivery.next_attempt_at
  end

  test "max attempts moves delivery to dead letter without scheduling another retry" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      attempts_count: WebhookDelivery::MAX_ATTEMPTS - 1,
      payload: { "status" => "settled" }
    )
    http_client = Class.new do
      def self.deliver!(_delivery)
        Sandbox::WebhookHttpClient::Response.new(503, "unavailable")
      end
    end

    assert_no_enqueued_jobs only: WebhookDeliveryJob do
      delivery.deliver!(http_client: http_client)
    end

    assert_equal "dead", delivery.status
    assert_nil delivery.next_attempt_at
  end

  test "replay resets delivery attempt budget" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      status: "dead",
      attempts_count: WebhookDelivery::MAX_ATTEMPTS,
      next_attempt_at: nil,
      last_error: "HTTP 503",
      last_response_status: 503,
      payload: { "status" => "settled" }
    )

    assert_enqueued_with(job: WebhookDeliveryJob, args: [ delivery.id ]) do
      delivery.replay!
    end

    assert_equal "pending", delivery.status
    assert_equal 0, delivery.attempts_count
    assert_nil delivery.next_attempt_at
    assert_nil delivery.last_error
    assert_nil delivery.last_response_status
  end

  test "operational updates preserve the original delivery signature" do
    app, = create_developer_app
    delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "settled" }
    )
    original_signature = delivery.signature
    app.update_column(:webhook_signing_secret_ciphertext, DeveloperApp.encrypt_secret("whsec_sandbox_rotated"))
    http_client = Class.new do
      class << self
        attr_accessor :signature
      end

      def self.deliver!(delivery)
        self.signature = delivery.delivery_headers.fetch("X-OpenBank-Signature")
        Sandbox::WebhookHttpClient::Response.new(202, "accepted")
      end
    end

    delivery.deliver!(http_client: http_client)

    assert_equal original_signature, http_client.signature
    assert_equal original_signature, delivery.reload.signature
  end

  test "canonical payload is stable for nested hashes" do
    app, = create_developer_app
    first_delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 123,
      payload: {
        "event_type" => "payment.settled",
        "payment" => { "status" => "settled", "amount_cents" => 9_900 },
        "meta" => { "branch" => "0001", "account" => "12345-6" }
      }
    )
    second_delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 124,
      signature_timestamp: first_delivery.signature_timestamp,
      payload: {
        "meta" => { "account" => "12345-6", "branch" => "0001" },
        "payment" => { "amount_cents" => 9_900, "status" => "settled" },
        "event_type" => "payment.settled"
      }
    )

    assert_equal first_delivery.canonical_payload, second_delivery.canonical_payload
    assert_equal first_delivery.signature, second_delivery.signature
  end
end
