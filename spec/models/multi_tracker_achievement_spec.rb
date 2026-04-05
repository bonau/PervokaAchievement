require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe MultiTrackerAchievement, type: :model do
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

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when user has issues in 3+ trackers' do
      trackers = Tracker.limit(3)
      if trackers.count >= 3
        trackers.each do |tracker|
          Issue.create!(
            project_id: 1, tracker_id: tracker.id, subject: "Tracker #{tracker.id}",
            author_id: user.id, status_id: 1, priority: priority
          )
        end
        issue = Issue.where(author_id: user.id).last
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be true
      end
    end

    it 'does not award when user has issues in fewer than 3 trackers' do
      Issue.where(author_id: user.id).destroy_all
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Single tracker',
        author_id: user.id, status_id: 1, priority: priority
      )
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
