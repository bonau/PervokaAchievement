class AddTimestampsToAchievement < ActiveRecord::Migration[4.2]
  def up
    add_column :achievements, :created_at, :datetime
    add_column :achievements, :updated_at, :datetime
  end

  def down
    remove_column :achievements, :created_at
    remove_column :achievements, :updated_at
  end
end
