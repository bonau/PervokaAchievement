class AddNotifiedAtToAchievements < ActiveRecord::Migration[7.0]
  def change
    add_column :achievements, :notified_at, :datetime, default: nil
  end
end
