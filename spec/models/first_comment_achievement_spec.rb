require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe FirstCommentAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules, :journals

  let(:user) { User.find(2) }
  let(:issue) { Issue.find(1) }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :social' do
    expect(described_class.category).to eq :social
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when journal has notes' do
      let(:journal) do
        Journal.new(journalized: issue, user: user, notes: 'A comment')
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(journal)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when journal has blank notes' do
      let(:journal) do
        Journal.new(journalized: issue, user: user, notes: '')
      end

      it 'does not award the achievement' do
        described_class.check_conditions_for(journal)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      let(:journal) do
        Journal.new(journalized: issue, user: user, notes: 'Another comment')
      end

      before { described_class.check_conditions_for(journal) }

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(journal)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
