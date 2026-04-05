class SelfAssignedAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    10
  end

  def self.tags
    [:fun]
  end

  def self.check_conditions_for(issue)
    user = User.current
    return unless user.is_a?(User)

    super(user, issue) do |u, i|
      i.assigned_to_id == u.id && i.author_id == u.id
    end
  end
end
