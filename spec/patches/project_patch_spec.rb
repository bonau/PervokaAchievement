require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::ProjectPatch, type: :model do
  fixtures :users, :projects

  let(:project) { Project.find(1) }
  let(:user)    { User.find(2) }

  before  { User.current = user }
  after   { User.current = nil }

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

    it 'returns the original close result' do
      result = project.close
      expect(result).to be_truthy
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

    it 'returns the original reopen result' do
      result = project.reopen
      expect(result).to be_truthy
    end
  end
end
