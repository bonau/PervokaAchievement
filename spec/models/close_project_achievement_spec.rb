require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe CloseProjectAchievement, type: :model do
  fixtures :users, :projects

  let(:user) { User.find(2) }
  let(:project) { Project.find(1) }

  before  { User.current = user }
  after   { User.current = nil }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when the project is closed' do
      before do
        project.update!(status: Project::STATUS_CLOSED)
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(project)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when the project is still active' do
      before do
        project.update!(status: Project::STATUS_ACTIVE)
      end

      it 'does not award the achievement' do
        described_class.check_conditions_for(project)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      before do
        project.update!(status: Project::STATUS_CLOSED)
        described_class.check_conditions_for(project)
      end

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(project)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
