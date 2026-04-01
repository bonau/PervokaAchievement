require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe CreateFirstIssueAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when user created an issue' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'My First Issue',
          author_id: user.id, status_id: 1, priority: priority
        )
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when issue author is not the user' do
      let(:other_user) { User.find(1) }

      before { other_user.achievements.where(type: described_class.name).destroy_all }

      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Other Issue',
          author_id: other_user.id, status_id: 1, priority: priority
        )
      end

      it 'awards to the author, not the current user' do
        described_class.check_conditions_for(issue)
        expect(other_user.awarded?(described_class)).to be true
      end
    end

    context 'when already awarded' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'My First Issue',
          author_id: user.id, status_id: 1, priority: priority
        )
      end

      before { described_class.check_conditions_for(issue) }

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(issue)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
