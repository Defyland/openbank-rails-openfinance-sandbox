class Account < ApplicationRecord
  ACCOUNT_TYPES = %w[checking savings payment].freeze
  STATUSES = %w[active blocked closed].freeze

  belongs_to :sandbox_customer
  has_many :ledger_transactions, dependent: :restrict_with_exception
  has_many :payment_initiations, dependent: :restrict_with_exception

  before_validation :assign_external_id, on: :create

  validates :external_id, presence: true, uniqueness: true
  validates :account_type, inclusion: { in: ACCOUNT_TYPES }
  validates :branch_code, :number, :check_digit, :currency, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :available_balance_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def debit!(amount_cents)
    with_lock do
      raise Sandbox::InsufficientFundsError, "Insufficient account balance." if available_balance_cents < amount_cents

      update!(available_balance_cents: available_balance_cents - amount_cents)
    end
  end

  private

  def assign_external_id
    self.external_id ||= "acc_#{SecureRandom.hex(8)}"
  end
end
