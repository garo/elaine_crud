# frozen_string_literal: true

class Tag < ApplicationRecord
  has_and_belongs_to_many :books

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true

  default_scope { order(:name) }
end
