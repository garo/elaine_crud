class AddEbookUrlToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :ebook_url, :string
  end
end
