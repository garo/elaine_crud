# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit Page Update with Validation Errors', type: :feature do
  before do
    reset_database
  end

  describe 'Submitting invalid data from /books/:id/edit page' do
    let!(:library) { Library.first }
    let!(:author) { Author.first }
    let!(:book) { Book.first }

    it 'replicates the @filterable_columns nil error when update fails validation' do
      # Visit the edit page - the book is already in edit mode (shown in edit_row partial)
      visit "/books/#{book.id}/edit"

      # Should load successfully
      expect(page).to have_content("Edit Book (ID: #{book.id})")

      # The edit page shows the book in an edit form at the bottom
      # with "Save Changes" and "Cancel" buttons
      expect(page).to have_button('Save Changes')

      # Find the title input field and clear it
      # Look for book[title] input
      title_input = find("input[name='book[title]']")
      title_input.fill_in with: ''

      # Submit the form with empty title (validation should fail)
      # This form has from_inline_edit=true hidden field
      # So the update action will use: elsif params[:from_inline_edit] branch
      # Which renders 'elaine_crud/base/index'
      # The index view includes _search_bar.html.erb
      # Which calls @filterable_columns.any? - causing the error if not set
      click_button 'Save Changes'

      # The page should not crash with nil error
      expect(page).not_to have_content('undefined method')
      expect(page).not_to have_content("any?' for nil")
      expect(page).not_to have_content('NoMethodError')

      # Instead, it should show the validation error
      # The error is displayed in the inline edit form (edit_row partial)
      # which shows "Title" label and "can't be blank" as separate text
      expect(page).to have_content("can't be blank")

      # And the page should still render correctly (status 422)
      expect(page.status_code).to eq(422)
    end
  end
end
