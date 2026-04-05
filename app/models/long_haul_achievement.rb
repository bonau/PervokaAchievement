class LongHaulAchievement < Achievement
  def self.category
    :issue
  end

  def self.points
    20
  end

  def self.tags
    [:skill, :milestone]
  end

  def self.check_conditions_for(issue)
    user = User.current
    return unless user.is_a?(User)

    super(user, issue) do |_u, i|
      i.closed? && i.created_on.present? && (Time.current - i.created_on) >= 30.days
    end
  end
end
