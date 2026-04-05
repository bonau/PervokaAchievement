require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe NightOwlAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }
  let(:issue) do
    Issue.create!(
      project_id: 1, tracker_id: 1, subject: 'Late night work',
      author_id: user.id, status_id: 1, priority: priority
    )
  end

  before { User.current = user }
  after { User.current = nil }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when current time is between 10pm and 5am' do
      allow(Time).to receive(:current).and_return(Time.new(2026, 1, 1, 23, 30))
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award during business hours' do
      allow(Time).to receive(:current).and_return(Time.new(2026, 1, 1, 14, 0))
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
