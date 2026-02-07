class AchievementsController < ApplicationController
  unloadable

  def index
    @all_achievement_classes = Achievement.registered_achievements
    @user_achievements = User.current.achievements
    @unlocked_achievement_classes = @user_achievements.map{ |a| a.class }.uniq
    @unlockable_achievement_classes = @all_achievement_classes - @unlocked_achievement_classes
  end
end
