class Consent < ApplicationRecord
  STATUSES = %w[awaiting_authorization authorized revoked expired rejected].freeze
  PERMISSIONS = %w[ACCOUNTS_READ BALANCES_READ TRANSACTIONS_READ PAYMENTS_INITIATE WEBHOOKS_READ].freeze

  belongs_to :developer_app
  belongs_to :sandbox_customer
  has_many :access_tokens, dependent: :restrict_with_exception
  has_many :payment_initiations, dependent: :restrict_with_exception

  before_validation :assign_external_id, on: :create
  before_validation :assign_expiration, on: :create

  validates :external_id, presence: true, uniqueness: { scope: :developer_app_id }
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true
  validate :permissions_are_supported

  scope :active, -> { where(status: "authorized").where("expires_at > ?", Time.current) }

  def active?
    status == "authorized" && expires_at.future? && revoked_at.nil?
  end

  def allows?(permission)
    active? && permissions.include?(permission)
  end

  def authorize!
    with_lock do
      return false if status == "authorized" && revoked_at.nil?

      assert_transition!(target: "authorized", from: %w[awaiting_authorization])
      update!(status: "authorized", authorized_at: Time.current, revoked_at: nil)
    end
  end

  def revoke!
    with_lock do
      return false if status == "revoked"

      assert_transition!(target: "revoked", from: %w[authorized])
      update!(status: "revoked", revoked_at: Time.current)
      access_tokens.where(revoked_at: nil).find_each(&:revoke!)
      true
    end
  end

  def expire!
    with_lock do
      return false if status == "expired"

      assert_transition!(target: "expired", from: %w[authorized])
      update!(status: "expired")
      access_tokens.where(revoked_at: nil).find_each(&:revoke!)
      true
    end
  end

  private

  def assign_external_id
    self.external_id ||= "cns_#{SecureRandom.hex(10)}"
  end

  def assign_expiration
    self.expires_at ||= 90.days.from_now
  end

  def permissions_are_supported
    invalid_permissions = Array(permissions) - PERMISSIONS
    errors.add(:permissions, "contain unsupported values: #{invalid_permissions.join(', ')}") if invalid_permissions.any?
  end

  def assert_transition!(target:, from:)
    return if from.include?(status)

    errors.add(:status, "cannot transition from #{status} to #{target}")
    raise ActiveRecord::RecordInvalid, self
  end
end
