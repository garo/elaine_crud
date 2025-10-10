class BookCopy < ApplicationRecord
  belongs_to :book
  belongs_to :library
  has_one :loan, dependent: :destroy

  validates :rfid, presence: true, uniqueness: true

  scope :available, -> { where(available: true) }

  # Delegate common book attributes for convenience
  delegate :title, :isbn, :author, to: :book, prefix: true
end
