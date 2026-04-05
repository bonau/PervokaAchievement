class AchievementsController < ApplicationController
  before_action :require_login
  before_action :check_view_permission

  def index
    @target_user = User.current
    load_achievements_for(@target_user)
    @user_setting = AchievementUserSetting.for(User.current)
  end

  def show
    @target_user = User.find(params[:id])
    unless can_view_profile?(@target_user)
      deny_access
      return
    end
    load_achievements_for(@target_user)
  end

  def leaderboard
    users_with_achievements = User.joins(:achievements)
      .where(type: 'User', status: User::STATUS_ACTIVE)
      .distinct
    @leaderboard = users_with_achievements.map do |user|
      { user: user, score: user.achievement_score, count: user.achievements.size }
    end.sort_by { |entry| -entry[:score] }
  end

  def update_visibility
    setting = AchievementUserSetting.for(User.current)
    setting.public_profile = params[:public_profile] == '1'
    setting.save!
    flash[:notice] = l(:notice_successful_update)
    redirect_to achievements_path
  end

  private

  def check_view_permission
    deny_access unless User.current.allowed_to?(:view_achievements, nil, global: true)
  end

  def can_view_profile?(user)
    return true if user == User.current
    return true if User.current.admin?
    AchievementUserSetting.public_profile?(user)
  end

  def load_achievements_for(user)
    @all_achievement_classes = Achievement.registered_achievements.select { |a| AchievementSetting.enabled?(a) }
    @user_achievements = user.achievements
    @unlocked_achievement_classes = @user_achievements.map { |a| a.class }.uniq
    @unlockable_achievement_classes = @all_achievement_classes - @unlocked_achievement_classes

    @achievements_by_category = Achievement.categories.each_with_object({}) do |cat, hash|
      unlocked = @user_achievements.select { |a| a.class.category == cat }
      unlockable = @unlockable_achievement_classes.select { |a| a.category == cat }
      hash[cat] = { unlocked: unlocked, unlockable: unlockable } if unlocked.any? || unlockable.any?
    end

    @progresses = AchievementProgress.where(user_id: user.id).index_by(&:achievement_type)
  end
end
