class CreateBookCopies < ActiveRecord::Migration[8.0]
  def change
    create_table :book_copies do |t|
      t.references :book, null: false, foreign_key: true
      t.references :library, null: false, foreign_key: true
      t.string :rfid, null: false
      t.boolean :available, default: true

      t.timestamps
    end
    add_index :book_copies, :rfid, unique: true
  end
end
