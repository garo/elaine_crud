class CreateBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :isbn, null: false
      t.integer :publication_year
      t.integer :pages
      t.text :description
      t.boolean :available, default: true
      t.decimal :price, precision: 10, scale: 2
      t.references :author, null: false, foreign_key: true
      t.references :library, null: false, foreign_key: true

      t.timestamps
    end

    add_index :books, :isbn, unique: true
    add_index :books, :title
  end
end
