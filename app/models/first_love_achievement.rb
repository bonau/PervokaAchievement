class FirstLoveAchievement < Achievement
  def self.check_conditions_for(user)
    super(user) { |user| Issue.where(:assigned_to_id => ([user.id] + user.group_ids)).size > 0 }
  end
end
