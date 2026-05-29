class SandboxScenario < ApplicationRecord
  STATUSES = %w[active retired].freeze

  validates :code, :name, :description, presence: true
  validates :code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
end
