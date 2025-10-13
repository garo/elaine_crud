# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Books CRUD', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all books' do
      visit '/books'
      expect_no_errors
      expect(page).to have_content('Books')
      expect(count_table_rows).to eq(Book.count)
    end

    it 'displays book details with custom layout' do
      book = Book.first
      visit '/books'
      expect(page).to have_content(book.title)
      expect(page).to have_content(book.isbn)
      expect(page).to have_content(book.author.name)
    end

    it 'displays multi-row layout with description on second row' do
      book = Book.first
      visit '/books'
      expect(page).to have_content(book.description)
    end

    it 'displays price formatted as currency' do
      book = Book.first
      visit '/books'
      expect(page).to have_content("$#{book.price.to_i}")
    end

    it 'displays availability badge' do
      book = Book.where(available: true).first
      visit '/books'
      expect(page).to have_content('Available')
    end
  end

  describe 'Creating a book' do
    it 'shows new book form with dropdowns' do
      visit '/books/new'
      expect_no_errors
      expect(page).to have_content('New Book')
      expect(page).to have_field('book[title]')
      expect(page).to have_field('book[isbn]')
      expect(page).to have_select('book[author_id]')
      # Books no longer have library_id - library is associated through book_copies
    end

    it 'creates a new book successfully' do
      visit '/books/new'

      fill_in 'book[title]', with: 'Test Book'
      fill_in 'book[isbn]', with: '978-0-123-45678-9'
      select Author.first.name, from: 'book[author_id]'
      # Books no longer have library_id
      fill_in 'book[publication_year]', with: '2024'
      fill_in 'book[pages]', with: '300'
      fill_in 'book[price]', with: '19.99'
      fill_in 'book[description]', with: 'A test book description'

      initial_count = Book.count
      click_button 'Create Book'

      expect(Book.count).to eq(initial_count + 1)
    end
  end

  describe 'Editing a book' do
    it 'shows edit book form' do
      book = Book.first
      visit "/books/#{book.id}/edit"
      expect_no_errors
      expect(page).to have_content("Edit Book")
      expect(page).to have_field('book[title]', with: book.title)
    end

    it 'updates book successfully' do
      book = Book.first
      visit "/books/#{book.id}/edit"

      new_title = 'Updated Book Title'
      fill_in 'book[title]', with: new_title
      click_button 'Save Changes'

      book.reload
      expect(book.title).to eq(new_title)
    end
  end

  describe 'Deleting a book' do
    it 'deletes book successfully' do
      book = Book.create!(
        title: 'Book to Delete',
        isbn: '978-0-999-99999-9',
        author: Author.first,
        publication_year: 2024,
        pages: 100,
        price: 9.99
      )

      visit '/books'
      initial_count = Book.count

      # Find delete button within the turbo-frame for this record
      within("turbo-frame#record_#{book.id}") do
        click_button 'Delete'
      end

      expect(Book.count).to eq(initial_count - 1)
    end
  end
end
