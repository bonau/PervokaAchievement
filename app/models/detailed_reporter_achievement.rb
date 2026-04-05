class DetailedReporterAchievement < Achievement
  def self.category
    :social
  end

  def self.points
    15
  end

  def self.tags
    [:skill, :exploratory]
  end

  def self.check_conditions_for(journal)
    user = journal.user
    return unless user.is_a?(User)

    super(user, journal) do |_u, j|
      j.notes.present? && j.notes.length >= 200
    end
  end
end
