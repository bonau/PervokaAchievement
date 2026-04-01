class AchievementsController < ApplicationController
  before_action :require_login

  def index
    @all_achievement_classes = Achievement.registered_achievements
    @user_achievements = User.current.achievements
    @unlocked_achievement_classes = @user_achievements.map { |a| a.class }.uniq
    @unlockable_achievement_classes = @all_achievement_classes - @unlocked_achievement_classes

    @achievements_by_category = Achievement.categories.each_with_object({}) do |cat, hash|
      unlocked = @user_achievements.select { |a| a.class.category == cat }
      unlockable = @unlockable_achievement_classes.select { |a| a.category == cat }
      hash[cat] = { unlocked: unlocked, unlockable: unlockable } if unlocked.any? || unlockable.any?
    end
  end
end
