class ItMustBeKiddingAchievement < Achievement
  def self.check_conditions_for(project)
    user = User.current
    project.reload
    super(user, project) { |user, project| project.status == Project::STATUS_ACTIVE }
  end
end
