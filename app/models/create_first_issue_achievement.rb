class CreateFirstIssueAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    10
  end

  def self.tags
    [:milestone]
  end

  def self.check_conditions_for(issue)
    user = issue.author
    return unless user.is_a?(User)

    super(user, issue) { |u, _i| Issue.where(author_id: u.id).exists? }
  end
end
