class SandboxCustomer < ApplicationRecord
  SEGMENTS = %w[retail premium sme].freeze
  RISK_PROFILES = %w[standard enhanced blocked].freeze

  has_many :accounts, dependent: :restrict_with_exception
  has_many :consents, dependent: :restrict_with_exception

  before_validation :assign_external_id, on: :create

  validates :external_id, presence: true, uniqueness: true
  validates :document_number, presence: true, uniqueness: true
  validates :full_name, presence: true
  validates :segment, inclusion: { in: SEGMENTS }
  validates :risk_profile, inclusion: { in: RISK_PROFILES }

  private

  def assign_external_id
    self.external_id ||= "cus_#{SecureRandom.hex(8)}"
  end
end
