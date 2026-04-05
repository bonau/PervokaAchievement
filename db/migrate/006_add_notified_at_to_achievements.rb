class AddNotifiedAtToAchievements < ActiveRecord::Migration[6.1]
  def change
    add_column :achievements, :notified_at, :datetime, default: nil
  end
end
