class Library < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :librarians, dependent: :destroy

  validates :name, presence: true
  validates :city, presence: true
end
