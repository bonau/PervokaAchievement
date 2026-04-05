require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe WeekendWarriorAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }
  let(:issue) do
    Issue.create!(
      project_id: 1, tracker_id: 1, subject: 'Weekend work',
      author_id: user.id, status_id: 1, priority: priority
    )
  end

  before { User.current = user }
  after { User.current = nil }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when current day is Saturday' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 4, 4)) # Saturday
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'awards when current day is Sunday' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 4, 5)) # Sunday
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award on weekdays' do
      allow(Date).to receive(:current).and_return(Date.new(2026, 4, 6)) # Monday
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
