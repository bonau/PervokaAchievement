class PaperworkAchievement < Achievement
  def self.category
    :general
  end

  def self.points
    10
  end

  def self.tags
    [:exploratory]
  end

  def self.check_conditions_for(attachment)
    user = attachment.author
    return unless user.is_a?(User)
    return unless attachment.container.is_a?(Project) || attachment.container.is_a?(Issue) || attachment.container.is_a?(WikiPage)

    super(user, attachment) do |_u, a|
      !a.image?
    end
  end
end
