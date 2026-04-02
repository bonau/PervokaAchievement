require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe WikiEditorAchievement, type: :model do
  fixtures :users, :projects, :wikis, :wiki_pages, :wiki_contents,
           :roles, :members, :member_roles, :enabled_modules

  let(:user) { User.find(2) }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :wiki' do
    expect(described_class.category).to eq :wiki
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when user edits a wiki page' do
      let(:wiki_content) do
        wc = WikiContent.first
        wc = WikiContent.new if wc.nil?
        allow(wc).to receive(:author).and_return(user)
        wc
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(wiki_content)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when already awarded' do
      let(:wiki_content) do
        wc = WikiContent.first
        wc = WikiContent.new if wc.nil?
        allow(wc).to receive(:author).and_return(user)
        wc
      end

      before { described_class.check_conditions_for(wiki_content) }

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(wiki_content)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
