class AchievementUserSetting < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true

  def self.for(user)
    find_or_initialize_by(user_id: user.id)
  end

  def self.public_profile?(user)
    setting = find_by(user_id: user.id)
    setting&.public_profile? || false
  end
end
