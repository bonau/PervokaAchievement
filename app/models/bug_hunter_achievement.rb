class BugHunterAchievement < Achievement
  def self.category
    :issue
  end

  def self.check_conditions_for(issue)
    user = issue.author
    return unless user.is_a?(User)
    return unless issue.tracker.present?

    super(user, issue) { |_u, i| i.tracker.name.casecmp('bug').zero? }
  end
end
