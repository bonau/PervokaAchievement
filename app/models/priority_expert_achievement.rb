class PriorityExpertAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    15
  end

  def self.tags
    [:skill]
  end

  def self.check_conditions_for(issue)
    user = User.current
    return unless user.is_a?(User)

    super(user, issue) do |_u, i|
      i.closed? && i.priority.present? && i.priority.position <= 2
    end
  end
end
