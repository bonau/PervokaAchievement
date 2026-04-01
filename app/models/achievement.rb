class Achievement < ActiveRecord::Base
  CATEGORIES = [:issue, :project, :wiki, :social, :general].freeze

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

  def self.categories
    CATEGORIES
  end

  def deliver_mail
    Mailer.achievement_unlocked(user, self).deliver_later
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

  def self.check_conditions_for(user, *args, &block)
    if user and !user.awarded?(self) and yield(user, *args)
      user.award(self)
    end
  end

  def self.inherited(base)
    super
    Achievement.registered_achievements << base
  end
end
