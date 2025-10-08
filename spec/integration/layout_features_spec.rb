# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom Layout Features', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Multi-row layout (Books)' do
    it 'displays books with two-row layout' do
      book = Book.first
      visit '/books'

      # First row should have: title, isbn, author, library, year, pages, price, available
      # Second row should have: description (spanning multiple columns), loans

      # Check that description is displayed (second row field)
      expect(page).to have_content(book.description)

      # Check that loans info is displayed (either count or "items:")
      expect(page).to have_content('items:') # The actual format from seeds
    end

    it 'applies correct colspan to description field' do
      visit '/books'

      # Find a cell with description content
      description_cells = page.all('div[class*="col-span"]').select do |cell|
        cell.text.include?('dystopian') || cell.text.include?('magical')
      end

      # At least one description cell should have colspan
      expect(description_cells).not_to be_empty
    end
  end

  describe 'Custom column widths with minmax()' do
    it 'uses flexible grid columns for libraries' do
      visit '/libraries'

      # Check that page rendered without errors
      expect_no_errors

      # Verify grid is being used (grid class on container)
      expect(page).to have_selector('div.grid')
    end

    it 'uses flexible grid columns for books' do
      visit '/books'
      expect_no_errors
      expect(page).to have_selector('div.grid')
    end

    it 'uses flexible grid columns for members' do
      visit '/members'
      expect_no_errors
      expect(page).to have_selector('div.grid')
    end

    it 'uses flexible grid columns for librarians' do
      visit '/librarians'
      expect_no_errors
      expect(page).to have_selector('div.grid')
    end
  end

  describe 'Responsive horizontal scrolling' do
    it 'allows horizontal scroll when content is too wide' do
      visit '/books'

      # Check that overflow container exists
      expect(page).to have_selector('div.overflow-x-auto')
    end
  end

  describe 'Custom field display' do
    it 'displays currency fields with dollar sign' do
      book = Book.first
      visit '/books'
      # Check for dollar sign (currency formatting)
      expect(page.text).to match(/\$\d+/)

      librarian = Librarian.first
      visit '/librarians'
      # Check for dollar sign (currency formatting)
      expect(page.text).to match(/\$\d+/)
    end

    it 'displays date fields with custom formatting' do
      library = Library.first
      visit '/libraries'
      formatted_date = library.established_date&.strftime("%B %Y")
      expect(page).to have_content(formatted_date) if formatted_date

      librarian = Librarian.first
      visit '/librarians'
      formatted_hire_date = librarian.hire_date.strftime("%B %d, %Y")
      expect(page).to have_content(formatted_hire_date)
    end

    it 'displays boolean fields with custom badges' do
      book = Book.where(available: true).first
      visit '/books'
      expect(page).to have_content('Available')

      unavailable_book = Book.where(available: false).first
      if unavailable_book
        expect(page).to have_content('Checked Out')
      end
    end

    it 'displays email fields as mailto links' do
      library = Library.first
      visit '/libraries'
      expect(page).to have_selector("a[href='mailto:#{library.email}']")

      member = Member.first
      visit '/members'
      expect(page).to have_selector("a[href='mailto:#{member.email}']")
    end
  end

  describe 'Grid borders and styling' do
    it 'applies borders to grid cells' do
      visit '/libraries'

      # Check that cells have border classes
      cells = page.all('div.border-r')
      expect(cells.count).to be > 0
    end

    it 'applies alternating row colors' do
      visit '/libraries'

      # Check for bg-white and bg-gray-50 classes
      expect(page).to have_selector('div.bg-white')
      expect(page).to have_selector('div.bg-gray-50')
    end

    it 'applies hover effects to rows' do
      visit '/libraries'

      # Check for hover:bg-blue-50 class
      expect(page).to have_selector('div.hover\\:bg-blue-50')
    end
  end
end
