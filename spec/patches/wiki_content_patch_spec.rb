require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::WikiContentPatch, type: :model do
  fixtures :users, :projects, :wikis, :wiki_pages, :wiki_contents,
           :roles, :members, :member_roles, :enabled_modules

  let(:user) { User.find(2) }

  describe '#check_achievement' do
    it 'is defined on WikiContent' do
      expect(WikiContent.new).to respond_to(:check_achievement)
    end
  end

  describe 'after_save callback' do
    it 'calls WikiEditorAchievement.check_conditions_for' do
      wiki_content = WikiContent.first
      skip 'No wiki_contents in fixtures' if wiki_content.nil?

      expect(WikiEditorAchievement).to receive(:check_conditions_for).with(wiki_content)
      wiki_content.update!(text: 'Updated wiki content')
    end
  end
end
