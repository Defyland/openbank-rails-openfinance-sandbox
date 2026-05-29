class LedgerTransaction < ApplicationRecord
  TRANSACTION_TYPES = %w[credit debit].freeze

  belongs_to :account

  before_validation :assign_external_id, on: :create
  before_validation :assign_posted_at, on: :create

  validates :external_id, presence: true, uniqueness: { scope: :account_id }
  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, :description, :category, :posted_at, presence: true

  def signed_amount_cents
    transaction_type == "credit" ? amount_cents : -amount_cents
  end

  private

  def assign_external_id
    self.external_id ||= "txn_#{SecureRandom.hex(10)}"
  end

  def assign_posted_at
    self.posted_at ||= Time.current
  end
end
