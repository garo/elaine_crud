class Book < ApplicationRecord
  belongs_to :author
  belongs_to :library
  has_many :loans, dependent: :destroy

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true

  scope :available, -> { where(available: true) }
end
