class SpeedRunnerAchievement < Achievement
  def self.category
    :issue
  end

  def self.check_conditions_for(issue)
    user = User.current
    return unless user.is_a?(User)

    super(user, issue) { |_u, i| i.closed? && i.created_on.present? && (Time.current - i.created_on) < 24.hours }
  end
end
