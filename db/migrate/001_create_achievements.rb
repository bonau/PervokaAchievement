class CreateAchievements < ActiveRecord::Migration[4.2]
  def change
    create_table :achievements do |t|
      t.references :user
      t.string :type
    end
  end
end
