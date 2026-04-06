class AchievementsController < ApplicationController
  before_action :require_login
  before_action :check_view_permission
  accept_api_auth :index, :show, :leaderboard

  def index
    @target_user = User.current
    load_achievements_for(@target_user)
    @user_setting = AchievementUserSetting.for(User.current)

    respond_to do |format|
      format.html
      format.json { render json: achievements_json(@target_user) }
    end
  end

  def show
    @target_user = User.find(params[:id])
    unless can_view_profile?(@target_user)
      deny_access
      return
    end
    load_achievements_for(@target_user)

    respond_to do |format|
      format.html
      format.json { render json: achievements_json(@target_user) }
    end
  end

  def leaderboard
    users_with_achievements = User.joins(:achievements)
      .where(type: 'User', status: User::STATUS_ACTIVE)
      .includes(:achievements)
      .distinct
    settings_cache = AchievementSetting.all.index_by(&:achievement_type)
    @leaderboard = users_with_achievements.map do |user|
      score = user.achievements.sum { |a| a.class.effective_points(settings_cache) }
      { user: user, score: score, count: user.achievements.size }
    end.sort_by { |entry| -entry[:score] }

    respond_to do |format|
      format.html
      format.json { render json: leaderboard_json }
    end
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

  def achievement_class_json(klass)
    {
      type: klass.name,
      name: klass.parameter_name,
      category: klass.category,
      tier: klass.tier,
      points: klass.effective_points,
      tags: klass.tags,
      target_count: klass.target_count,
    }
  end

  def achievement_json(achievement)
    achievement_class_json(achievement.class).merge(
      id: achievement.id,
      unlocked_at: achievement.created_at&.iso8601,
    )
  end

  def achievements_json(user)
    progresses = AchievementProgress.where(user_id: user.id).index_by(&:achievement_type)

    {
      user: { id: user.id, login: user.login, name: user.name },
      total_score: user.achievement_score,
      unlocked: @user_achievements.map { |a| achievement_json(a) },
      locked: @unlockable_achievement_classes.map { |klass|
        progress = progresses[klass.name]
        achievement_class_json(klass).merge(
          progress: progress ? { current: progress.current_count, target: progress.target_count, percentage: progress.percentage } : nil,
        )
      },
    }
  end

  def leaderboard_json
    {
      leaderboard: @leaderboard.map.with_index(1) { |entry, rank|
        {
          rank: rank,
          user: { id: entry[:user].id, login: entry[:user].login, name: entry[:user].name },
          score: entry[:score],
          achievement_count: entry[:count],
        }
      },
    }
  end
end
