require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::MemberPatch, type: :model do
  fixtures :users, :projects, :roles, :members, :member_roles, :enabled_modules

  let(:user) { User.find(2) }

  describe '#check_achievement' do
    it 'is defined on Member' do
      expect(Member.new).to respond_to(:check_achievement)
    end
  end

  describe 'after_create callback' do
    it 'calls TeamPlayerAchievement.check_conditions_for' do
      project = Project.where.not(id: user.memberships.select(:project_id)).first
      skip 'No available project for new membership' if project.nil?
      role = Role.first

      expect(TeamPlayerAchievement).to receive(:check_conditions_for)
      Member.create!(user: user, project: project, role_ids: [role.id])
    end
  end
end
