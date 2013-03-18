class Achievement < ActiveRecord::Base
  unloadable
  belongs_to :user
  after_save :deliver_mail
  validates_presence_of :user

  class << self
    attr_accessor :registered_achievements
  end

  self.registered_achievements = []

  def deliver_mail
    Mailer.achievement_unlocked(self).deliver
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

  def self.check_conditions_for(user, &block)
    if !user.awarded?(self) and yield(user)
      user.award(self)
    end
  end

  def self.inherited(base)
    Achievement.registered_achievements << base
  end
end
