class AccessToken < ApplicationRecord
  TOKEN_TTL = 30.minutes

  belongs_to :developer_app
  belongs_to :consent

  attr_reader :plain_token

  before_validation :assign_token, on: :create
  before_validation :assign_expiration, on: :create

  validates :token_digest, presence: true, uniqueness: true
  validates :token_last_eight, presence: true, length: { is: 8 }
  validates :expires_at, presence: true
  validate :permissions_subset_consent

  def self.issue!(developer_app:, consent:)
    raise Security::AuthorizationError, "Consent is not active." unless consent.active?
    raise Security::AuthorizationError, "Consent belongs to another client." unless consent.developer_app_id == developer_app.id

    create!(
      developer_app: developer_app,
      consent: consent,
      permissions: consent.permissions
    )
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def active?
    revoked_at.nil? && expires_at.future? && consent.active?
  end

  def allows?(permission)
    active? && permissions.include?(permission)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def mark_used!
    update_column(:last_used_at, Time.current)
  end

  private

  def assign_token
    @plain_token ||= "tok_sandbox_#{SecureRandom.hex(32)}"
    self.token_digest ||= self.class.digest(@plain_token)
    self.token_last_eight ||= @plain_token.last(8)
  end

  def assign_expiration
    self.expires_at ||= TOKEN_TTL.from_now
  end

  def permissions_subset_consent
    return if consent.nil?

    invalid_permissions = Array(permissions) - Array(consent.permissions)
    errors.add(:permissions, "must be a subset of the consent permissions") if invalid_permissions.any?
  end
end
