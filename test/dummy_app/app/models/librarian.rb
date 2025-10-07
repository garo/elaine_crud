class Librarian < ApplicationRecord
  belongs_to :library

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[Manager Assistant Clerk Archivist] }
end
