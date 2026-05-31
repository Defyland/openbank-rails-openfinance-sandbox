class WebhookDelivery < ApplicationRecord
  STATUSES = %w[pending delivered failed dead].freeze
  MAX_ATTEMPTS = 3

  belongs_to :developer_app

  before_validation :assign_event_id, on: :create
  before_validation :assign_idempotency_key, on: :create
  before_validation :assign_signature_timestamp, on: :create
  before_validation :assign_signature

  validates :event_id, :event_type, :aggregate_type, :aggregate_id, :payload, :signature, :idempotency_key, presence: true
  validates :event_id, :idempotency_key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :attempts_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.generate_event_id
    "evt_#{SecureRandom.hex(12)}"
  end

  def self.enqueue!(developer_app:, event_type:, aggregate:, payload:, correlation_id:, event_id: nil)
    delivery = create!(
      developer_app: developer_app,
      event_id: event_id,
      event_type: event_type,
      aggregate_type: aggregate.class.name,
      aggregate_id: aggregate.id,
      payload: payload,
      correlation_id: correlation_id
    )
    WebhookDeliveryJob.perform_later(delivery.id)
    delivery
  end

  def deliver!(http_client: nil)
    http_client ||= configured_http_client

    with_lock do
      return false if status == "delivered"

      increment!(:attempts_count)

      if Sandbox::ScenarioRegistry.webhook_failure?(developer_app.active_scenario_code) || developer_app.webhook_url.include?("fail")
        fail_delivery!("Sandbox scenario forced webhook failure.", response_status: nil)
      else
        response = http_client.deliver!(self)
        if response.success?
          update!(
            status: "delivered",
            delivered_at: Time.current,
            next_attempt_at: nil,
            last_error: nil,
            last_response_status: response.status
          )
        else
          fail_delivery!("HTTP #{response.status}: #{response.body}".truncate(500), response_status: response.status)
        end
      end
    rescue Sandbox::WebhookHttpClient::DeliveryError => error
      fail_delivery!(error.message.truncate(500), response_status: nil)
    end

    schedule_retry_if_needed!
    status == "delivered"
  end

  def replay!
    update!(status: "pending", next_attempt_at: nil, delivered_at: nil, last_error: nil, last_response_status: nil)
    WebhookDeliveryJob.perform_later(id)
  end

  def canonical_payload
    JSON.generate(canonicalize_payload(payload))
  end

  def delivery_headers
    {
      "Content-Type" => "application/json",
      "User-Agent" => "OpenBank-Sandbox-Webhook/1.0",
      "Idempotency-Key" => idempotency_key,
      "X-OpenBank-Event-ID" => event_id,
      "X-OpenBank-Event-Type" => event_type,
      "X-OpenBank-Signature" => signature,
      "X-OpenBank-Signature-Timestamp" => signature_timestamp_value.iso8601,
      "X-Correlation-ID" => correlation_id
    }.compact
  end

  private

  def assign_event_id
    self.event_id ||= self.class.generate_event_id
  end

  def assign_idempotency_key
    self.idempotency_key ||= "#{developer_app_id}:#{event_type}:#{aggregate_type}:#{aggregate_id}:#{event_id}"
  end

  def assign_signature_timestamp
    self.signature_timestamp ||= Time.current
  end

  def assign_signature
    return if developer_app.nil?

    self.signature = OpenSSL::HMAC.hexdigest("SHA256", developer_app.webhook_signing_secret, signature_base)
  end

  def fail_delivery!(message, response_status:)
    if attempts_count >= MAX_ATTEMPTS
      update!(status: "dead", next_attempt_at: nil, last_error: message, last_response_status: response_status)
    else
      update!(
        status: "failed",
        next_attempt_at: attempts_count.minutes.from_now,
        last_error: message,
        last_response_status: response_status
      )
    end
  end

  def schedule_retry_if_needed!
    return unless status == "failed" && next_attempt_at.present?

    WebhookDeliveryJob.set(wait_until: next_attempt_at).perform_later(id)
  end

  def configured_http_client
    Rails.application.config.x.webhook_http_client || Sandbox::WebhookHttpClient
  end

  def signature_base
    "#{signature_timestamp_value.iso8601}.#{canonical_payload}"
  end

  def signature_timestamp_value
    signature_timestamp || created_at || Time.current
  end

  def canonicalize_payload(value)
    case value
    when Hash
      value.deep_stringify_keys.sort.to_h { |key, nested_value| [ key, canonicalize_payload(nested_value) ] }
    when Array
      value.map { |item| canonicalize_payload(item) }
    else
      value
    end
  end
end
