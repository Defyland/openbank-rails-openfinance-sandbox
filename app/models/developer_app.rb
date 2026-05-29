class DeveloperApp < ApplicationRecord
  STATUSES = %w[active suspended].freeze

  has_many :consents, dependent: :restrict_with_exception
  has_many :access_tokens, dependent: :restrict_with_exception
  has_many :payment_initiations, dependent: :restrict_with_exception
  has_many :webhook_deliveries, dependent: :restrict_with_exception

  attr_reader :plain_client_secret

  before_validation :assign_credentials, on: :create
  before_validation :normalize_webhook_url

  validates :name, presence: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret_digest, presence: true
  validates :webhook_url, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :rate_limit_per_minute, numericality: { only_integer: true, greater_than: 0 }
  validate :active_scenario_must_exist

  def active?
    status == "active"
  end

  def authenticate_secret?(secret)
    return false if secret.blank?

    ActiveSupport::SecurityUtils.secure_compare(self.class.digest(secret), client_secret_digest)
  end

  def webhook_signing_secret
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "webhooks/#{client_secret_digest}")
  end

  def self.digest(value)
    OpenSSL::Digest::SHA256.hexdigest(value.to_s)
  end

  private

  def assign_credentials
    self.client_id ||= "app_#{SecureRandom.hex(10)}"
    @plain_client_secret ||= "sk_sandbox_#{SecureRandom.hex(24)}"
    self.client_secret_digest ||= self.class.digest(@plain_client_secret)
  end

  def normalize_webhook_url
    self.webhook_url = webhook_url.to_s.strip
  end

  def active_scenario_must_exist
    return if Sandbox::ScenarioRegistry.known?(active_scenario_code)

    errors.add(:active_scenario_code, "is not supported")
  end
end
