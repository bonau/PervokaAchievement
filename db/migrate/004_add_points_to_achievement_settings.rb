class AddPointsToAchievementSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :achievement_settings, :custom_points, :integer, default: nil
  end
end
