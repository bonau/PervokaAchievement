require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe ResolveFirstIssueAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }
  let(:closed_status) { IssueStatus.where(is_closed: true).first }

  before { User.current = user }
  after { User.current = nil }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when issue is closed' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Test Issue',
          author_id: 1, assigned_to_id: user.id, status_id: 1,
          priority: priority
        )
      end

      before do
        issue.reload
        issue.status = closed_status
        issue.save!
      end

      it 'awards the achievement to User.current' do
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when issue is not closed' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Open Issue',
          author_id: 1, status_id: 1, priority: priority
        )
      end

      it 'does not award the achievement' do
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Test Issue',
          author_id: 1, status_id: 1, priority: priority
        )
      end

      before do
        issue.reload
        issue.status = closed_status
        issue.save!
        described_class.check_conditions_for(issue)
      end

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(issue)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
