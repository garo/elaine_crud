class Author < ApplicationRecord
  has_many :books, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
