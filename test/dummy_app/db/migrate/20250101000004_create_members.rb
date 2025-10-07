class CreateMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :membership_type, null: false
      t.date :joined_at
      t.boolean :active, default: true
      t.references :library, null: false, foreign_key: true

      t.timestamps
    end

    add_index :members, :email
    add_index :members, :membership_type
  end
end
