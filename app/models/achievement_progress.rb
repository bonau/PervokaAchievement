class AchievementProgress < ActiveRecord::Base
  belongs_to :user

  validates :achievement_type, presence: true
  validates :user_id, uniqueness: { scope: :achievement_type }

  def self.for(user, achievement_class)
    find_or_initialize_by(user_id: user.id, achievement_type: achievement_class.name)
  end

  def target_count
    achievement_class&.target_count
  end

  def percentage
    return 0 unless target_count&.positive?
    [(current_count.to_f / target_count * 100).floor, 100].min
  end

  def complete?
    target_count && current_count >= target_count
  end

  private

  def achievement_class
    achievement_type.safe_constantize
  end
end
