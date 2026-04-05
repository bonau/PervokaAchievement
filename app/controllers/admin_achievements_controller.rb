class AdminAchievementsController < ApplicationController
  before_action :require_admin

  layout 'admin'

  def index
    @achievement_classes = Achievement.registered_achievements
    @settings = AchievementSetting.all.index_by(&:achievement_type)
  end

  def bulk_update
    params[:settings]&.each do |achievement_type, attrs|
      setting = AchievementSetting.find_or_initialize_by(
        achievement_type: achievement_type
      )
      setting.update(
        enabled: attrs[:enabled] == '1',
        custom_points: attrs[:custom_points].presence&.to_i,
        custom_title: attrs[:custom_title].presence,
        custom_description: attrs[:custom_description].presence,
        custom_quote: attrs[:custom_quote].presence
      )
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to admin_achievements_path
  end
end
