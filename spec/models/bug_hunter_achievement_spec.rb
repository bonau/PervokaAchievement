require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe BugHunterAchievement, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules

  let(:user) { User.find(2) }
  let(:priority) { IssuePriority.first }
  let(:bug_tracker) { Tracker.find_by(name: 'Bug') || Tracker.first }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when user creates a Bug-type issue' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker: bug_tracker, subject: 'Found a bug',
          author_id: user.id, status_id: 1, priority: priority
        )
      end

      it 'awards the achievement if tracker is Bug' do
        skip 'No Bug tracker in fixtures' unless bug_tracker.name.casecmp('bug').zero?
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when user creates a non-Bug issue' do
      let(:non_bug_tracker) { Tracker.where.not(name: 'Bug').first || Tracker.first }
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker: non_bug_tracker, subject: 'Feature request',
          author_id: user.id, status_id: 1, priority: priority
        )
      end

      it 'does not award the achievement' do
        skip 'All trackers are named Bug' if non_bug_tracker.name.casecmp('bug').zero?
        described_class.check_conditions_for(issue)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      let(:issue) do
        Issue.create!(
          project_id: 1, tracker: bug_tracker, subject: 'Another bug',
          author_id: user.id, status_id: 1, priority: priority
        )
      end

      before do
        skip 'No Bug tracker in fixtures' unless bug_tracker.name.casecmp('bug').zero?
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
