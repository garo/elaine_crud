# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit Page Validation Errors', type: :feature do
  before do
    reset_database
  end

  describe 'Editing a record via /books/:id/edit page' do
    let!(:library) { Library.first }
    let!(:author) { Author.first }
    let!(:book) { Book.first }

    it 'loads edit page without nil errors (regression test)' do
      # This test verifies the fix for the @filterable_columns.any? error
      # that occurred when visiting /books/:id/edit directly
      visit "/books/#{book.id}/edit"

      # Should load successfully without nil errors
      expect(page).to have_content("Edit Book (ID: #{book.id})")
      expect(page).not_to have_content('undefined method')
      expect(page).not_to have_content("any?' for nil")
      expect(page).not_to have_content('NoMethodError')

      # Page should render successfully with 200 status
      expect(page.status_code).to eq(200)
    end

    it 'shows all books in the grid view' do
      visit "/books/#{book.id}/edit"

      # Should show the book grid
      expect(count_table_rows).to be > 0
    end
  end
end
