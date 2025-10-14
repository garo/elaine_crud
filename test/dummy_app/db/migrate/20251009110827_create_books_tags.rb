class CreateBooksTags < ActiveRecord::Migration[8.0]
  def change
    create_table :books_tags, id: false do |t|
      t.belongs_to :book, null: false, foreign_key: true
      t.belongs_to :tag, null: false, foreign_key: true
    end

    add_index :books_tags, [:book_id, :tag_id], unique: true
  end
end
