require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::ProjectPatch, type: :model do
  fixtures :users, :projects

  let(:project) { Project.find(1) }
  let(:user)    { User.find(2) }

  before  { User.current = user }
  after   { User.current = nil }

  describe 'method aliasing' do
    it 'defines old_close' do
      expect(project).to respond_to(:old_close)
    end

    it 'defines old_reopen' do
      expect(project).to respond_to(:old_reopen)
    end
  end

  describe '#close' do
    it 'triggers CloseProjectAchievement.check_conditions_for' do
      expect(CloseProjectAchievement).to receive(:check_conditions_for).with(project)
      project.close
    end

    it 'changes the project status to closed' do
      project.close
      project.reload
      expect(project.status).to eq Project::STATUS_CLOSED
    end
  end

  describe '#reopen' do
    before do
      project.update!(status: Project::STATUS_CLOSED)
    end

    it 'triggers ItMustBeKiddingAchievement.check_conditions_for' do
      expect(ItMustBeKiddingAchievement).to receive(:check_conditions_for).with(project)
      project.reopen
    end

    it 'changes the project status to active' do
      project.reopen
      project.reload
      expect(project.status).to eq Project::STATUS_ACTIVE
    end
  end
end
