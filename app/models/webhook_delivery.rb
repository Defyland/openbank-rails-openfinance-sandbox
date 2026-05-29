class WebhookDelivery < ApplicationRecord
  STATUSES = %w[pending delivered failed dead].freeze
  MAX_ATTEMPTS = 3

  belongs_to :developer_app

  before_validation :assign_event_id, on: :create
  before_validation :assign_idempotency_key, on: :create
  before_validation :assign_signature

  validates :event_id, :event_type, :aggregate_type, :aggregate_id, :payload, :signature, :idempotency_key, presence: true
  validates :event_id, :idempotency_key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :attempts_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.enqueue!(developer_app:, event_type:, aggregate:, payload:, correlation_id:)
    delivery = create!(
      developer_app: developer_app,
      event_type: event_type,
      aggregate_type: aggregate.class.name,
      aggregate_id: aggregate.id,
      payload: payload,
      correlation_id: correlation_id
    )
    WebhookDeliveryJob.perform_later(delivery.id)
    delivery
  end

  def deliver!
    with_lock do
      increment!(:attempts_count)

      if Sandbox::ScenarioRegistry.webhook_failure?(developer_app.active_scenario_code) || developer_app.webhook_url.include?("fail")
        fail_delivery!("Sandbox scenario forced webhook failure.")
      else
        update!(status: "delivered", delivered_at: Time.current, next_attempt_at: nil, last_error: nil)
      end
    end
  end

  def replay!
    update!(status: "pending", next_attempt_at: nil, delivered_at: nil, last_error: nil)
    WebhookDeliveryJob.perform_later(id)
  end

  def canonical_payload
    JSON.generate(canonicalize_payload(payload))
  end

  private

  def assign_event_id
    self.event_id ||= "evt_#{SecureRandom.hex(12)}"
  end

  def assign_idempotency_key
    self.idempotency_key ||= "#{developer_app_id}:#{event_type}:#{aggregate_type}:#{aggregate_id}:#{event_id}"
  end

  def assign_signature
    return if developer_app.nil?

    self.signature = OpenSSL::HMAC.hexdigest("SHA256", developer_app.webhook_signing_secret, canonical_payload)
  end

  def fail_delivery!(message)
    if attempts_count >= MAX_ATTEMPTS
      update!(status: "dead", next_attempt_at: nil, last_error: message)
    else
      update!(status: "failed", next_attempt_at: attempts_count.minutes.from_now, last_error: message)
    end
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
