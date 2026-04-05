require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PaperworkAchievement, type: :model do
  fixtures :users, :projects

  let(:user) { User.find(2) }
  let(:project) { Project.find(1) }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :general' do
    expect(described_class.category).to eq :general
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards when uploading a non-image file' do
      attachment = double('Attachment',
        author: user,
        container: project,
        image?: false
      )
      described_class.check_conditions_for(attachment)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award when uploading an image' do
      attachment = double('Attachment',
        author: user,
        container: project,
        image?: true
      )
      described_class.check_conditions_for(attachment)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
