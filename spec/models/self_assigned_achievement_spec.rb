require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe SelfAssignedAchievement, type: :model do
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

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when user creates and assigns issue to themselves' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Self assigned',
        author_id: user.id, assigned_to_id: user.id,
        status_id: 1, priority: priority
      )
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award when issue is assigned to someone else' do
      other_user = User.find(3)
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Other assigned',
        author_id: user.id, assigned_to_id: other_user.id,
        status_id: 1, priority: priority
      )
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
