class Achievement < ActiveRecord::Base
  CATEGORIES = [:issue, :project, :wiki, :social, :general].freeze
  TAGS = [:milestone, :exploratory, :fun, :skill, :teamwork].freeze

  belongs_to :user
  after_create :deliver_mail
  validates_presence_of :user

  class << self
    attr_accessor :registered_achievements
  end

  self.registered_achievements = []

  def self.category
    :general
  end

  def self.points
    10
  end

  def self.effective_points
    setting = AchievementSetting.find_by(achievement_type: name)
    setting&.custom_points || points
  end

  def self.tags
    []
  end

  def self.all_tags
    TAGS
  end

  def self.categories
    CATEGORIES
  end

  def deliver_mail
    Mailer.achievement_unlocked(user, self).deliver_later
  end

  def self.icon_name
    parameter_name.chomp('_achievement')
  end

  def self.parameter_name
    self.name.underscore
  end

  def self.locale_prefix(name = nil)
    "achievement." + self.parameter_name + ( name ? "." + name.to_s : "" )
  end

  def locale_prefix(name = nil)
    self.class.locale_prefix(name)
  end

  # Override in subclasses to set a target count for progress-based achievements.
  # nil means single-stage (the default award-on-condition behavior).
  def self.target_count
    nil
  end

  def self.check_conditions_for(user, *args, &block)
    return unless AchievementSetting.enabled?(self)
    if user and !user.awarded?(self) and yield(user, *args)
      user.award(self)
    end
  end

  # Increment progress toward a multi-stage achievement.
  # Awards automatically when target_count is reached.
  def self.increment_progress_for(user, increment: 1)
    return unless target_count
    return unless AchievementSetting.enabled?(self)
    return if user.awarded?(self)

    progress = AchievementProgress.for(user, self)
    progress.current_count = (progress.current_count || 0) + increment
    progress.save!
    user.award(self) if progress.complete?
  end

  def self.inherited(base)
    super
    Achievement.registered_achievements << base
  end
end
