class AchievementSetting < ActiveRecord::Base
  validates :achievement_type, presence: true, uniqueness: true
  validates :enabled, inclusion: { in: [true, false] }

  def self.for(achievement_class)
    find_or_initialize_by(achievement_type: achievement_class.name)
  end

  def self.enabled?(achievement_class)
    setting = find_by(achievement_type: achievement_class.name)
    setting.nil? || setting.enabled?
  end

  def display_text(field, locale_key)
    custom = send("custom_#{field}")
    custom.presence || I18n.t(locale_key)
  end
end
