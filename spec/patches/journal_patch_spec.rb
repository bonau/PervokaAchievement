require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::JournalPatch, type: :model do
  fixtures :users, :projects, :issues, :trackers, :issue_statuses,
           :enumerations, :projects_trackers, :roles, :members,
           :member_roles, :enabled_modules, :journals

  let(:user) { User.find(2) }
  let(:issue) { Issue.find(1) }

  describe '#check_achievement' do
    it 'is defined on Journal' do
      journal = Journal.new(journalized: issue, user: user)
      expect(journal).to respond_to(:check_achievement)
    end
  end

  describe 'after_create callback' do
    it 'calls FirstCommentAchievement.check_conditions_for' do
      expect(FirstCommentAchievement).to receive(:check_conditions_for)
      Journal.create!(journalized: issue, user: user, notes: 'Test comment')
    end
  end
end
