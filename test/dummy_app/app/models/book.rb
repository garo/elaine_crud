class Book < ApplicationRecord
  belongs_to :author
  has_many :book_copies, dependent: :destroy
  has_many :libraries, through: :book_copies
  has_many :loans, through: :book_copies
  has_and_belongs_to_many :tags

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true

  # A book is available if it has at least one available copy
  scope :available, -> { joins(:book_copies).where(book_copies: { available: true }).distinct }
end
