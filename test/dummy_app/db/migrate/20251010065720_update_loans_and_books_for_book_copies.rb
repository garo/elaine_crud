class UpdateLoansAndBooksForBookCopies < ActiveRecord::Migration[8.0]
  def change
    # Remove library_id from books (library relationship moves to book_copies)
    remove_reference :books, :library, foreign_key: true

    # Change loans to reference book_copy instead of book
    remove_reference :loans, :book, foreign_key: true
    add_reference :loans, :book_copy, null: false, foreign_key: true, index: true
  end
end
