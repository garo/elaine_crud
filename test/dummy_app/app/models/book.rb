class Book < ApplicationRecord
  belongs_to :author
  belongs_to :library
  has_many :loans, dependent: :destroy
  has_and_belongs_to_many :tags

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true

  scope :available, -> { where(available: true) }
end
