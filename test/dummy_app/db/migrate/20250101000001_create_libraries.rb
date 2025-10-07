class CreateLibraries < ActiveRecord::Migration[7.0]
  def change
    create_table :libraries do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :state
      t.string :phone
      t.string :email
      t.date :established_date

      t.timestamps
    end

    add_index :libraries, :name
  end
end
