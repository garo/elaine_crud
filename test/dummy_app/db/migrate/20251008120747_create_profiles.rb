class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :member, null: false, foreign_key: true
      t.text :bio
      t.string :avatar_url

      t.timestamps
    end
  end
end
