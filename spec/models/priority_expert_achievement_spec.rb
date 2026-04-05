require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PriorityExpertAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:closed_status) { IssueStatus.where(is_closed: true).first }

  before { User.current = user }
  after { User.current = nil }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when closing a high-priority issue (position <= 2)' do
      high_priority = IssuePriority.order(:position).first
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Urgent fix',
        author_id: user.id, status_id: 1, priority: high_priority
      )
      issue.reload
      issue.status = closed_status
      issue.save!
      described_class.check_conditions_for(issue)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award for low-priority issues' do
      low_priority = IssuePriority.order(:position).last
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Low priority',
        author_id: user.id, status_id: 1, priority: low_priority
      )
      issue.reload
      issue.status = closed_status
      issue.save!

      # Only awards if priority position <= 2
      if low_priority.position > 2
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be false
      end
    end
  end
end
