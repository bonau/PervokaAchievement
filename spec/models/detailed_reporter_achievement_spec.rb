require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe DetailedReporterAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }

  before { User.current = user }
  after { User.current = nil }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :social' do
    expect(described_class.category).to eq :social
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    let(:issue) do
      Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Test',
        author_id: user.id, status_id: 1, priority: priority
      )
    end

    it 'awards when journal note has 200+ characters' do
      journal = Journal.new(
        journalized: issue,
        user: user,
        notes: 'a' * 200
      )
      described_class.check_conditions_for(journal)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award when notes are shorter than 200 characters' do
      journal = Journal.new(
        journalized: issue,
        user: user,
        notes: 'Short comment'
      )
      described_class.check_conditions_for(journal)
      expect(user.awarded?(described_class)).to be false
    end

    it 'does not award when notes are blank' do
      journal = Journal.new(
        journalized: issue,
        user: user,
        notes: nil
      )
      described_class.check_conditions_for(journal)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
