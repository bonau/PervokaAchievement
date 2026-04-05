class CreateAchievementUserSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :achievement_user_settings do |t|
      t.references :user, null: false, index: { unique: true }
      t.boolean :public_profile, null: false, default: false
      t.timestamps
    end
  end
end
