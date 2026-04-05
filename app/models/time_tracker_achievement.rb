class TimeTrackerAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    10
  end

  def self.tags
    [:milestone]
  end

  def self.check_conditions_for(time_entry)
    user = time_entry.user
    return unless user.is_a?(User)

    super(user, time_entry) { |_u, _te| true }
  end
end
