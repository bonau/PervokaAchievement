class AddIndexOnAchievementsUserType < ActiveRecord::Migration[6.1]
  def change
    add_index :achievements, [:user_id, :type], name: 'idx_achievements_user_type'
  end
end
