module AchievementsHelper
  def achievement_icon(achievement, options = {})
    klass = achievement.is_a?(Class) ? achievement : achievement.class
    size = options.delete(:size) || 32
    image_tag("achievements/#{klass.icon_name}.svg",
      width: size, height: size,
      class: "achievement_icon #{options[:class]}".strip,
      alt: achievement_text(achievement, :title),
      plugin: 'pervoka_achievement')
  end

  def achievement_text(achievement, field)
    klass = achievement.is_a?(Class) ? achievement : achievement.class
    setting = achievement_settings_cache[klass.name]
    custom = setting&.send("custom_#{field}")
    custom.presence || l(klass.locale_prefix(field))
  end

  private

  def achievement_settings_cache
    @achievement_settings_cache ||= AchievementSetting.all.index_by(&:achievement_type)
  end
end
