class AchievementsController < ApplicationController
  before_action :require_login
  before_action :check_view_permission

  def index
    @all_achievement_classes = Achievement.registered_achievements.select { |a| AchievementSetting.enabled?(a) }
    @user_achievements = User.current.achievements
    @unlocked_achievement_classes = @user_achievements.map { |a| a.class }.uniq
    @unlockable_achievement_classes = @all_achievement_classes - @unlocked_achievement_classes

    @achievements_by_category = Achievement.categories.each_with_object({}) do |cat, hash|
      unlocked = @user_achievements.select { |a| a.class.category == cat }
      unlockable = @unlockable_achievement_classes.select { |a| a.category == cat }
      hash[cat] = { unlocked: unlocked, unlockable: unlockable } if unlocked.any? || unlockable.any?
    end
  end

  private

  def check_view_permission
    deny_access unless User.current.allowed_to?(:view_achievements, nil, global: true)
  end
end
