class Library < ApplicationRecord
  has_many :book_copies, dependent: :destroy
  has_many :books, through: :book_copies
  has_many :members, dependent: :destroy
  has_many :librarians, dependent: :destroy

  validates :name, presence: true
  validates :city, presence: true
end
