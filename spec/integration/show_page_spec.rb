# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Show Page', type: :feature do
  before do
    reset_database
  end

  describe 'Library show page' do
    it 'displays library details without crashing' do
      library = Library.first
      expect(library).not_to be_nil

      # Visit the show page - this should not crash
      visit library_path(library)

      # Should successfully load the page
      expect(page.status_code).to eq(200)
      expect(page).to have_content(library.name)
      expect(page).not_to have_content('Error')
      expect(page).not_to have_content('Exception')
    end

    it 'displays library details for all libraries' do
      # Test all libraries to ensure none crash
      Library.all.each do |library|
        # Visit the show page
        visit library_path(library)

        # Should display library information
        expect(page.status_code).to eq(200)
        expect(page).to have_content(library.name)
        expect(page).to have_content(library.city) if library.city.present?
      end
    end
  end

  describe 'Book show page' do
    it 'displays book details without crashing' do
      book = Book.first
      expect(book).not_to be_nil

      # Visit the show page
      visit book_path(book)

      # Should successfully load the page
      expect(page.status_code).to eq(200)
      expect(page).to have_content(book.title)
      expect(page).not_to have_content('Error')
    end
  end

  describe 'Author show page' do
    it 'displays author details without crashing' do
      author = Author.first
      expect(author).not_to be_nil

      # Visit the show page
      visit author_path(author)

      # Should successfully load the page
      expect(page.status_code).to eq(200)
      expect(page).to have_content(author.name)
    end
  end
end
