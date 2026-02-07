class AttachAPictureAchievement < Achievement
  def self.check_conditions_for(attachment)
    user = attachment.author
    super(user, attachment) { |user, attachment| attachment.image? and attachment.project.is_a?(Project) }
  end
end
