class Loan < ApplicationRecord
  belongs_to :book_copy
  belongs_to :member

  # Delegate to get book information through book_copy
  delegate :book, :library, to: :book_copy

  validates :due_date, presence: true
  validates :status, inclusion: { in: %w[pending active returned overdue] }

  scope :active, -> { where(status: 'active') }
  scope :overdue, -> { where('due_date < ? AND status = ?', Date.today, 'active') }

  # Auto-update status based on dates
  def check_overdue!
    if status == 'active' && due_date < Date.today
      update(status: 'overdue')
    end
  end
end
