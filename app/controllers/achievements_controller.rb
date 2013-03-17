class AchievementsController < ApplicationController
  unloadable

  def index
    @all_achievement_classes = Achievement.registered_achievements
    @user_achievements = User.current.achievements
  end
end
