class Member < ApplicationRecord
  belongs_to :library
  has_many :loans, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :membership_type, inclusion: { in: %w[Standard Premium Student Senior] }

  scope :active, -> { where(active: true) }
end
