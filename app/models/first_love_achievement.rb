class FirstLoveAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    10
  end

  def self.check_conditions_for(user)
    return unless user.is_a?(User)

    super(user) { |user| Issue.where(:assigned_to_id => ([user.id] + user.group_ids)).size > 0 }
  end
end
