class CreateAchievementProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :achievement_progresses, id: :integer do |t|
      t.references :user, null: false, type: :integer
      t.string :achievement_type, null: false
      t.integer :current_count, default: 0, null: false
      t.timestamps
    end
    add_index :achievement_progresses, [:user_id, :achievement_type], unique: true, name: 'idx_achievement_progresses_user_type'
  end
end
