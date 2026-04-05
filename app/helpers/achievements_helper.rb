module AchievementsHelper
  def achievement_text(achievement, field)
    klass = achievement.is_a?(Class) ? achievement : achievement.class
    setting = AchievementSetting.find_by(achievement_type: klass.name)
    custom = setting&.send("custom_#{field}")
    custom.presence || l(klass.locale_prefix(field))
  end
end
