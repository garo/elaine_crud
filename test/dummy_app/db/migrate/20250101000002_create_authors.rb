class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.text :biography
      t.integer :birth_year
      t.string :country
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :authors, :name
  end
end
