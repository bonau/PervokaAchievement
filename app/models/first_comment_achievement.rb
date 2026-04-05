class FirstCommentAchievement < Achievement
  def self.category
    :social
  end

  def self.points
    10
  end

  def self.tags
    [:milestone, :teamwork]
  end

  def self.check_conditions_for(journal)
    user = journal.user
    return unless user.is_a?(User)

    super(user, journal) { |_u, j| j.notes.present? }
  end
end
