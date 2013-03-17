class AchievementsController < ApplicationController
  unloadable

  def index
    @all_achievements = Achievement.registered_achievements
    @user_achievements = User.current.achievements
  end
end
