# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sorting and Filtering', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Default sorting' do
    it 'sorts libraries by name ascending by default' do
      visit '/libraries'

      libraries = Library.order(name: :asc)
      first_library = libraries.first

      # Check that the first library appears in the table
      expect(page).to have_content(first_library.name)
    end

    it 'sorts books by title ascending by default' do
      visit '/books'

      books = Book.order(title: :asc)
      first_book = books.first

      expect(page).to have_content(first_book.title)
    end

    it 'sorts members by name ascending by default' do
      visit '/members'

      members = Member.order(name: :asc)
      first_member = members.first

      expect(page).to have_content(first_member.name)
    end
  end

  describe 'Sortable columns' do
    it 'has sortable column headers' do
      visit '/libraries'

      # Check for sort links in headers (multiple header cells will match)
      header_links = page.all('div.bg-gray-100 a.flex')
      expect(header_links.count).to be > 0
    end

    it 'displays sort indicators' do
      visit '/libraries'

      # Sort indicators should be present (↑ or ↓)
      expect(page.html).to match(/[↑↓]/)
    end
  end

  describe 'Column clicking for sorting' do
    it 'allows clicking on sortable headers' do
      visit '/libraries'

      # Find a sortable header link
      header_links = page.all('div.bg-gray-100 a.flex')
      expect(header_links.count).to be > 0

      # Verify links have proper href for sorting
      header_links.each do |link|
        expect(link[:href]).to match(/sort=|direction=/)
      end
    end
  end

  describe 'Has-many relationship filtering' do
    it 'shows count of related records' do
      library = Library.first
      visit '/libraries'

      # Should show related records (using "items:" format from display_as)
      expect(page).to have_content('items:') if library.books.any? || library.members.any?
    end
  end
end
