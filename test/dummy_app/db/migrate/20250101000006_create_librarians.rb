class CreateLibrarians < ActiveRecord::Migration[7.0]
  def change
    create_table :librarians do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, null: false
      t.date :hire_date
      t.decimal :salary, precision: 10, scale: 2
      t.references :library, null: false, foreign_key: true

      t.timestamps
    end

    add_index :librarians, :email
    add_index :librarians, :role
  end
end
