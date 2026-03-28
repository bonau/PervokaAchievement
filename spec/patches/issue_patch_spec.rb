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
      issue.save!
      expect { issue.check_achievement }.not_to raise_error
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
