class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: 12 }, allow_nil: true
end
