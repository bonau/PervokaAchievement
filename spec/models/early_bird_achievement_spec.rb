require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe EarlyBirdAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }
  let(:closed_status) { IssueStatus.where(is_closed: true).first }

  before { User.current = user }
  after { User.current = nil }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when issue is closed before due date' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Early close',
        author_id: user.id, status_id: 1, priority: priority,
        due_date: 5.days.from_now
      )
      issue.reload
      issue.status = closed_status
      issue.save!
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award when issue has no due date' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'No due date',
        author_id: user.id, status_id: 1, priority: priority
      )
      issue.reload
      issue.status = closed_status
      issue.save!
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end

    it 'does not award when issue is not closed' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Still open',
        author_id: user.id, status_id: 1, priority: priority,
        due_date: 5.days.from_now
      )
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
