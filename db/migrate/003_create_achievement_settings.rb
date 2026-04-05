class CreateAchievementSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :achievement_settings do |t|
      t.string :achievement_type, null: false
      t.boolean :enabled, default: true, null: false
      t.string :custom_title
      t.string :custom_description
      t.string :custom_quote
      t.timestamps
    end

    add_index :achievement_settings, :achievement_type, unique: true
  end
end
