require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe FirstLoveAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :issue_priorities, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when user has an assigned issue' do
      before do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Test Issue',
          author_id: 1, assigned_to_id: user.id, status_id: 1,
          priority: priority
        )
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(user)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when user has no assigned issues' do
      before { Issue.where(assigned_to_id: user.id).destroy_all }

      it 'does not award the achievement' do
        described_class.check_conditions_for(user)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      before do
        Issue.create!(
          project_id: 1, tracker_id: 1, subject: 'Test Issue',
          author_id: 1, assigned_to_id: user.id, status_id: 1,
          priority: priority
        )
        described_class.check_conditions_for(user)
      end

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(user)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
