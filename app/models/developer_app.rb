require "uri"

class DeveloperApp < ApplicationRecord
  STATUSES = %w[active suspended].freeze

  has_many :consents, dependent: :restrict_with_exception
  has_many :access_tokens, dependent: :restrict_with_exception
  has_many :payment_initiations, dependent: :restrict_with_exception
  has_many :webhook_deliveries, dependent: :restrict_with_exception

  attr_reader :plain_client_secret
  attr_reader :plain_webhook_signing_secret

  before_validation :assign_credentials, on: :create
  before_validation :assign_webhook_signing_secret, on: :create
  before_validation :normalize_webhook_url

  validates :name, presence: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret_digest, presence: true
  validates :webhook_url, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :rate_limit_per_minute, numericality: { only_integer: true, greater_than: 0 }
  validate :active_scenario_must_exist
  validate :webhook_url_must_be_http

  def active?
    status == "active"
  end

  def authenticate_secret?(secret)
    return false if secret.blank?

    ActiveSupport::SecurityUtils.secure_compare(self.class.digest(secret), client_secret_digest)
  end

  def webhook_signing_secret
    return plain_webhook_signing_secret if plain_webhook_signing_secret.present?
    return legacy_webhook_signing_secret if webhook_signing_secret_ciphertext.blank?

    self.class.decrypt_secret(webhook_signing_secret_ciphertext)
  end

  def self.digest(value)
    OpenSSL::Digest::SHA256.hexdigest(value.to_s)
  end

  def self.encrypt_secret(value)
    secret_encryptor.encrypt_and_sign(value)
  end

  def self.decrypt_secret(value)
    secret_encryptor.decrypt_and_verify(value)
  end

  def self.secret_encryptor
    key = Rails.application.key_generator.generate_key("developer-app-webhook-signing-secret", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

  private

  def assign_credentials
    self.client_id ||= "app_#{SecureRandom.hex(10)}"
    return if client_secret_digest.present?

    @plain_client_secret ||= "sk_sandbox_#{SecureRandom.hex(24)}"
    self.client_secret_digest = self.class.digest(@plain_client_secret)
  end

  def assign_webhook_signing_secret
    return if webhook_signing_secret_ciphertext.present?

    @plain_webhook_signing_secret ||= "whsec_sandbox_#{SecureRandom.hex(32)}"
    self.webhook_signing_secret_ciphertext = self.class.encrypt_secret(@plain_webhook_signing_secret)
  end

  def normalize_webhook_url
    self.webhook_url = webhook_url.to_s.strip
  end

  def active_scenario_must_exist
    return if Sandbox::ScenarioRegistry.known?(active_scenario_code)

    errors.add(:active_scenario_code, "is not supported")
  end

  def webhook_url_must_be_http
    uri = URI.parse(webhook_url.to_s)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:webhook_url, "must be an http or https URL")
  rescue URI::InvalidURIError
    errors.add(:webhook_url, "must be an http or https URL")
  end

  def legacy_webhook_signing_secret
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "webhooks/#{client_secret_digest}")
  end
end
