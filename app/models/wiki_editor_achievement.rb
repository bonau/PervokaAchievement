class WikiEditorAchievement < Achievement
  def self.category
    :wiki
  end

  def self.points
    10
  end

  def self.check_conditions_for(wiki_content)
    user = wiki_content.author
    return unless user.is_a?(User)

    super(user, wiki_content) { |_u, _wc| true }
  end
end
