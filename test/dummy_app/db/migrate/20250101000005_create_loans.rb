class CreateLoans < ActiveRecord::Migration[7.0]
  def change
    create_table :loans do |t|
      t.date :due_date, null: false
      t.datetime :returned_at
      t.string :status, null: false, default: 'pending'
      t.references :book, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true

      t.timestamps
    end

    add_index :loans, :status
    add_index :loans, :due_date
  end
end
