class AchievementSetting < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  validates :achievement_type, presence: true, uniqueness: true
  validates :enabled, inclusion: { in: [true, false] }

  before_validation :sanitize_custom_text

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

  private

  def sanitize_custom_text
    %i[custom_title custom_description custom_quote].each do |attr|
      value = send(attr)
      send(:"#{attr}=", strip_tags(value)) if value.present?
    end
  end
end
