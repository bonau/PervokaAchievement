require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::IssuePatch, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses

  let(:issue) { Issue.find(1) }
  let(:user)  { User.find(2) }

  describe '#check_achievement' do
    it 'is defined on Issue' do
      expect(issue).to respond_to(:check_achievement)
    end

    it 'delegates to FirstLoveAchievement.check_conditions_for with assigned_to' do
      issue.assigned_to = user
      expect(FirstLoveAchievement).to receive(:check_conditions_for).with(user)
      issue.check_achievement
    end

    it 'handles nil assigned_to without raising' do
      issue.assigned_to = nil
      expect { issue.check_achievement }.not_to raise_error
    end
  end

  describe 'after_save callback' do
    it 'calls check_achievement' do
      new_issue = Issue.new(
        project_id: 1, tracker_id: 1, subject: 'Test Issue',
        author_id: 1, assigned_to_id: user.id, status_id: 1
      )

      expect(new_issue).to receive(:check_achievement).at_least(:once)
      new_issue.save!
    end
  end
end
