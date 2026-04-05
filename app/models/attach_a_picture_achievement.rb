class AttachAPictureAchievement < Achievement
  def self.category
    :social
  end

  def self.points
    10
  end

  def self.tags
    [:exploratory]
  end

  def self.check_conditions_for(attachment)
    user = attachment.author
    super(user, attachment) { |user, attachment| attachment.image? and attachment.project.is_a?(Project) }
  end
end
