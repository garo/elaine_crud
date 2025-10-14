# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'roo'

RSpec.describe 'Data Export', type: :request do
  before do
    reset_database
  end

  let!(:library) { Library.first }
  let!(:books) { Book.limit(5).to_a }

  describe 'CSV export' do
    it 'exports all books as CSV' do
      get export_books_path(format: :csv)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/csv')
      expect(response.headers['Content-Disposition']).to include('books_')
      expect(response.headers['Content-Disposition']).to include('.csv')

      csv = CSV.parse(response.body, headers: true)
      expect(csv.length).to be >= 5
      expect(csv.headers).to include('Title', 'Author', 'Isbn', 'Price')
    end

    it 'includes correct data for each row' do
      get export_books_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      # Find the book that matches the first row (books are sorted by title)
      book = Book.find_by(title: first_row['Title'])

      expect(first_row['Title']).to eq(book.title)
      expect(first_row['Author']).to eq(book.author.name)
      expect(first_row['Isbn']).to eq(book.isbn)
      expect(first_row['Price']).to eq(book.price.to_s)
    end

    it 'respects search filters' do
      get export_books_path(format: :csv, search: books.first.title)

      csv = CSV.parse(response.body, headers: true)
      expect(csv.length).to eq(1)
      expect(csv.first['Title']).to eq(books.first.title)
    end

    it 'respects column filters' do
      get export_books_path(format: :csv, filter: { author_id: books.first.author_id })

      csv = CSV.parse(response.body, headers: true)
      csv.each do |row|
        book = Book.find_by(title: row['Title'])
        expect(book.author_id).to eq(books.first.author_id)
      end
    end

    it 'includes filtered suffix in filename when filtered' do
      get export_books_path(format: :csv, search: 'test')

      expect(response.headers['Content-Disposition']).to include('books_filtered_')
    end

    it 'formats dates correctly' do
      get export_books_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      # Check date format (YYYY-MM-DD) - using publication_year which is an integer in this model
      # Instead check a date field from another model
      get export_librarians_path(format: :csv)
      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      expect(first_row['Hired On']).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it 'formats booleans as Yes/No' do
      get export_books_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      expect(['Yes', 'No']).to include(first_row['Availability'])
    end

    it 'properly escapes CSV special characters (commas, quotes, newlines)' do
      # Create a book with special characters in title and description
      author = Author.first
      book_with_special_chars = Book.create!(
        title: 'Test, "Book" with Special Characters',
        description: "Line 1: This has a comma, quote \" and newline\nLine 2: More text",
        isbn: 'TEST-123',
        publication_year: 2024,
        pages: 100,
        price: 19.99,
        available: true,
        author: author
      )

      get export_books_path(format: :csv)

      # Parse CSV - this will fail if special characters aren't properly escaped
      csv = CSV.parse(response.body, headers: true)

      # Find the row with our test book
      test_row = csv.find { |row| row['Title'] == book_with_special_chars.title }

      expect(test_row).not_to be_nil, "Book with special characters should be in CSV export"
      expect(test_row['Title']).to eq('Test, "Book" with Special Characters')
      expect(test_row['Description']).to eq("Line 1: This has a comma, quote \" and newline\nLine 2: More text")
      expect(test_row['Isbn']).to eq('TEST-123')

      # Cleanup
      book_with_special_chars.destroy
    end
  end

  describe 'Excel export' do
    it 'exports all books as Excel' do
      get export_books_path(format: :xlsx)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('spreadsheetml.sheet')
      expect(response.headers['Content-Disposition']).to include('books_')
      expect(response.headers['Content-Disposition']).to include('.xlsx')
    end

    it 'creates valid Excel file' do
      get export_books_path(format: :xlsx)

      # Save the response body to a temp file for Roo to read
      temp_file = Tempfile.new(['export', '.xlsx'])
      temp_file.binmode
      temp_file.write(response.body)
      temp_file.rewind

      # Parse Excel file with Roo
      xlsx = Roo::Spreadsheet.open(temp_file.path)

      expect(xlsx).not_to be_nil
      expect(xlsx.sheets.first).to eq('Books')

      # Check headers (first row)
      headers = xlsx.row(1)
      expect(headers).to include('Title', 'Author', 'Isbn', 'Price')

      # Check data rows (at least 5 data rows + 1 header)
      expect(xlsx.last_row).to be >= 6

      temp_file.close
      temp_file.unlink
    end

    it 'respects search filters in Excel' do
      get export_books_path(format: :xlsx, search: books.first.title)

      # Save to temp file
      temp_file = Tempfile.new(['export', '.xlsx'])
      temp_file.binmode
      temp_file.write(response.body)
      temp_file.rewind

      xlsx = Roo::Spreadsheet.open(temp_file.path)

      # 1 header + 1 data row
      expect(xlsx.last_row).to eq(2)

      temp_file.close
      temp_file.unlink
    end
  end

  describe 'JSON export' do
    it 'exports all books as JSON' do
      get export_books_path(format: :json)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)

      expect(json).to be_an(Array)
      expect(json.length).to be >= 5
    end

    it 'includes correct fields in JSON' do
      get export_books_path(format: :json)

      json = JSON.parse(response.body)
      first_record = json.first

      # Find the book that matches the first record (sorted by title)
      book = Book.find_by(title: first_record['title'])

      expect(first_record['title']).to eq(book.title)
      expect(first_record['isbn']).to eq(book.isbn)
      expect(first_record.keys).to include('title', 'author_id', 'isbn', 'price', 'available')
    end

    it 'respects search filters in JSON' do
      get export_books_path(format: :json, search: books.first.title)

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['title']).to eq(books.first.title)
    end

    it 'formats dates as ISO 8601' do
      # Use librarians which have a date field
      get export_librarians_path(format: :json)

      json = JSON.parse(response.body)
      first_record = json.first

      # Date should be in YYYY-MM-DD format
      expect(first_record['hire_date']).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end

  describe 'Error cases' do
    it 'handles export when no records exist' do
      # Delete dependent records first to avoid foreign key constraints
      Loan.delete_all
      BookCopy.delete_all
      # Clear the books_tags join table
      ActiveRecord::Base.connection.execute("DELETE FROM books_tags")
      Book.delete_all

      get export_books_path(format: :csv)

      expect(response).to have_http_status(:success)

      csv = CSV.parse(response.body, headers: true)
      expect(csv.length).to eq(0)
      expect(csv.headers).to include('Title', 'Author', 'Isbn')
    end

    it 'redirects when record count exceeds max_export_records' do
      # Temporarily stub the class method
      allow(BooksController).to receive(:max_export_records).and_return(3)

      get export_books_path(format: :csv)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(books_path)

      # Check the flash message in the redirect location header
      expect(flash[:alert]).to include('Cannot export more than 3 records')
      expect(flash[:alert]).to include('Please apply filters to reduce the number of records')
    end
  end

  describe 'Export with relationships' do
    it 'exports belongs_to relationship display values' do
      get export_books_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      # Should show author name, not author_id
      book = Book.find_by(title: first_row['Title'])
      expect(first_row['Author']).to eq(book.author.name)
    end

    it 'exports has_many relationship counts' do
      get export_libraries_path(format: :csv)

      csv = CSV.parse(response.body, headers: true)
      first_row = csv.first

      library = Library.first
      expect(first_row['Librarians'].to_i).to eq(library.librarians.count)
    end
  end

  describe 'Filename generation' do
    it 'includes model name in filename' do
      get export_books_path(format: :csv)

      filename = response.headers['Content-Disposition']
      expect(filename).to include('books_')
    end

    it 'includes date in filename' do
      get export_books_path(format: :csv)

      filename = response.headers['Content-Disposition']
      expect(filename).to include(Date.today.strftime('%Y-%m-%d'))
    end

    it 'uses correct extension for each format' do
      get export_books_path(format: :csv)
      expect(response.headers['Content-Disposition']).to include('.csv')

      get export_books_path(format: :xlsx)
      expect(response.headers['Content-Disposition']).to include('.xlsx')
    end
  end
end
