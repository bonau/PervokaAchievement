class MultiTrackerAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    20
  end

  def self.tags
    [:exploratory, :skill]
  end

  def self.check_conditions_for(issue)
    user = issue.author
    return unless user.is_a?(User)

    super(user, issue) do |u, _i|
      Issue.where(author_id: u.id).joins(:tracker).distinct.count('trackers.id') >= 3
    end
  end
end
