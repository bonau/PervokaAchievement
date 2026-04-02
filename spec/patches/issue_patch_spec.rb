require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::IssuePatch, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :projects_trackers, :enumerations, :issue_categories,
           :roles, :members, :member_roles, :enabled_modules

  let(:issue) { Issue.find(1) }
  let(:user)  { User.find(2) }

  describe '#check_achievement' do
    it 'is defined on Issue' do
      expect(issue).to respond_to(:check_achievement)
    end

    it 'delegates to FirstLoveAchievement.check_conditions_for when assigned_to_id changed' do
      issue.assigned_to = user
      issue.save!
      expect(FirstLoveAchievement).to receive(:check_conditions_for).with(user)
      issue.check_achievement
    end

    it 'skips check when assigned_to_id did not change' do
      issue.save!
      expect(FirstLoveAchievement).not_to receive(:check_conditions_for)
      issue.update!(subject: 'Updated subject')
    end

    it 'handles nil assigned_to without raising' do
      issue.assigned_to = nil
      issue.save!
      expect { issue.check_achievement }.not_to raise_error
    end

    it 'handles Group assigned_to without raising' do
      group = Group.create!(lastname: 'TestGroup')
      issue.assigned_to = group
      allow(issue).to receive(:saved_change_to_assigned_to_id?).and_return(true)
      expect { issue.check_achievement }.not_to raise_error
    end
  end

  describe '#check_achievement for new issue creation' do
    let(:priority) { IssuePriority.first }

    it 'calls CreateFirstIssueAchievement.check_conditions_for on new issue' do
      expect(CreateFirstIssueAchievement).to receive(:check_conditions_for)
      Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'New Issue',
        author_id: user.id, status_id: 1, priority: priority
      )
    end

    it 'does not call CreateFirstIssueAchievement on existing issue update' do
      expect(CreateFirstIssueAchievement).not_to receive(:check_conditions_for)
      issue.update!(subject: 'Updated subject')
    end

    it 'calls BugHunterAchievement.check_conditions_for on new issue' do
      expect(BugHunterAchievement).to receive(:check_conditions_for)
      Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Bug Report',
        author_id: user.id, status_id: 1, priority: priority
      )
    end
  end

  describe '#check_achievement for issue status change to closed' do
    let(:priority) { IssuePriority.first }
    let(:closed_status) { IssueStatus.where(is_closed: true).first }

    it 'calls ResolveFirstIssueAchievement.check_conditions_for when status changes to closed' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Resolve Test',
        author_id: user.id, status_id: 1, priority: priority
      )
      issue.reload
      expect(ResolveFirstIssueAchievement).to receive(:check_conditions_for).with(issue)
      issue.update!(status: closed_status)
    end

    it 'calls SpeedRunnerAchievement.check_conditions_for when status changes to closed' do
      issue = Issue.create!(
        project_id: 1, tracker_id: 1, subject: 'Speed Test',
        author_id: user.id, status_id: 1, priority: priority
      )
      issue.reload
      expect(SpeedRunnerAchievement).to receive(:check_conditions_for).with(issue)
      issue.update!(status: closed_status)
    end

    it 'does not call ResolveFirstIssueAchievement when status does not change' do
      expect(ResolveFirstIssueAchievement).not_to receive(:check_conditions_for)
      issue.update!(subject: 'No status change')
    end
  end

  describe 'after_save callback' do
    it 'calls check_achievement on save' do
      expect(issue).to receive(:check_achievement).at_least(:once)
      issue.assigned_to = user
      issue.save!
    end
  end
end
