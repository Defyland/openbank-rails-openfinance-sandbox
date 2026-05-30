class PaymentInitiation < ApplicationRecord
  STATUSES = %w[accepted rejected settled].freeze

  attr_accessor :created_by_request

  belongs_to :developer_app
  belongs_to :consent
  belongs_to :account

  before_validation :assign_external_id, on: :create

  validates :external_id, presence: true, uniqueness: { scope: :developer_app_id }
  validates :external_reference, :idempotency_key, :request_fingerprint, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, :creditor_name, :creditor_document, :creditor_account, presence: true

  def accepted?
    status == "accepted"
  end

  def rejected?
    status == "rejected"
  end

  def settled?
    status == "settled"
  end

  def created_by_request?
    created_by_request == true
  end

  private

  def assign_external_id
    self.external_id ||= "pay_#{SecureRandom.hex(10)}"
  end
end
