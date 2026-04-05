class NightOwlAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    15
  end

  def self.tags
    [:fun]
  end

  def self.check_conditions_for(issue)
    user = User.current
    return unless user.is_a?(User)

    super(user, issue) { |_u, _i| hour = Time.current.hour; hour >= 22 || hour < 5 }
  end
end
