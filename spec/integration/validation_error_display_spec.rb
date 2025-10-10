# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Validation Error Display', type: :feature do
  before do
    reset_database
  end

  describe 'Creating a new record with validation errors' do
    it 'displays error summary at top of form' do
      visit '/books/new'

      # Try to create a book without required fields
      click_button 'Create Book'

      # Should show error summary
      expect(page).to have_content('prohibited this book from being saved')
      expect(page).to have_content("Title can't be blank")
      expect(page).to have_content("Isbn can't be blank")
    end

    it 'displays inline field-level errors' do
      visit '/books/new'

      # Try to create a book without required fields
      click_button 'Create Book'

      # Should show inline error messages next to fields
      # The error appears in a <p> tag with text-red-600 class right after the input
      expect(page).to have_css('p.text-red-600', text: "can't be blank", count: 2)
    end

    it 'adds red border to invalid fields' do
      visit '/books/new'

      # Try to create a book without required fields
      click_button 'Create Book'

      # Should have red borders on invalid fields
      # Look for inputs with border-red-500 class
      expect(page).to have_css('input.border-red-500', minimum: 1)
    end

    it 'preserves form values after validation error' do
      visit '/books/new'

      fill_in 'Title', with: 'Test Book'
      # Leave ISBN blank (required field)
      fill_in 'Pages', with: '300'

      click_button 'Create Book'

      # Should preserve entered values
      expect(page).to have_field('Title', with: 'Test Book')
      expect(page).to have_field('Pages', with: '300')

      # Should show error for missing ISBN
      expect(page).to have_content("Isbn can't be blank")
    end
  end


  describe 'Format validation errors' do
    let!(:library) { Library.create!(name: 'Test Library', city: 'Test City', state: 'TS', phone: '555-0100', email: 'test@test.com') }

    it 'displays email format validation error for librarian' do
      visit '/librarians/new'

      fill_in 'Name', with: 'Test Librarian'
      fill_in 'Email', with: 'invalid-email'
      select 'Manager', from: 'Role'
      select library.name, from: 'Library'

      click_button 'Create Librarian'

      # Should show format error in summary
      expect(page).to have_content('Email is invalid')

      # Should show inline error
      expect(page).to have_css('p.text-red-600', text: 'is invalid')

      # Should have red border on email field
      expect(page).to have_css('input#librarian_email.border-red-500')
    end
  end

  describe 'Uniqueness validation errors' do
    let!(:library) { Library.create!(name: 'Test Library', city: 'Test City', state: 'TS', phone: '555-0100', email: 'test@test.com') }
    let!(:author) { Author.create!(name: 'Test Author') }
    let!(:existing_book) { Book.create!(title: 'Existing Book', isbn: '999-888-777', author: author) }

    it 'displays uniqueness validation error' do
      visit '/books/new'

      fill_in 'Title', with: 'New Book'
      fill_in 'Isbn', with: '999-888-777'  # Same as existing book

      click_button 'Create Book'

      # Should show uniqueness error
      expect(page).to have_content('Isbn has already been taken')

      # Should show inline error
      expect(page).to have_css('p.text-red-600', text: 'has already been taken')

      # Should have red border on ISBN field
      expect(page).to have_css('input#book_isbn.border-red-500')
    end
  end

end
