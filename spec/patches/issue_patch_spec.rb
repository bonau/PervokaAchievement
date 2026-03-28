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

    it 'delegates to FirstLoveAchievement.check_conditions_for with assigned_to' do
      issue.assigned_to = user
      expect(FirstLoveAchievement).to receive(:check_conditions_for).with(user)
      issue.check_achievement
    end

    it 'handles nil assigned_to without raising' do
      issue.assigned_to = nil
      expect { issue.check_achievement }.not_to raise_error
    end

    it 'handles Group assigned_to without raising' do
      group = Group.create!(lastname: 'TestGroup')
      issue.assigned_to = group
      expect { issue.check_achievement }.not_to raise_error
    end
  end

  describe 'after_save callback' do
    it 'calls check_achievement' do
      expect(issue).to receive(:check_achievement).at_least(:once)
      issue.save!
    end
  end
end
