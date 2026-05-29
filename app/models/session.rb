class Session < ApplicationRecord
  MAX_AGE = 14.days
  TOUCH_INTERVAL = 5.minutes

  belongs_to :user

  scope :stale, -> { where("updated_at < ?", MAX_AGE.ago) }

  def self.trim_stale!
    stale.delete_all
  end

  def stale?
    updated_at < MAX_AGE.ago
  end

  def refresh_if_needed!
    touch if updated_at < TOUCH_INTERVAL.ago
    self
  end
end
