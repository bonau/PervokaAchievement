class TeamPlayerAchievement < Achievement
  def self.category
    :social
  end

  def self.points
    20
  end

  def self.tier
    :gold
  end

  def self.tags
    [:teamwork]
  end

  def self.check_conditions_for(member)
    user = member.principal
    return unless user.is_a?(User)

    super(user, member) do |u, _m|
      u.memberships.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count >= 3
    end
  end
end
