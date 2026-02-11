require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AttachAPictureAchievement, type: :model do
  fixtures :users, :projects, :attachments

  let(:user) { User.find(2) }
  let(:project) { Project.find(1) }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when the attachment is an image in a project' do
      let(:attachment) do
        att = Attachment.new(filename: 'test.png', author: user, container: project, content_type: 'image/png')
        allow(att).to receive(:image?).and_return(true)
        allow(att).to receive(:project).and_return(project)
        att
      end

      it 'awards the achievement' do
        described_class.check_conditions_for(attachment)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when the attachment is not an image' do
      let(:attachment) do
        att = Attachment.new(filename: 'test.pdf', author: user, container: project, content_type: 'application/pdf')
        allow(att).to receive(:image?).and_return(false)
        allow(att).to receive(:project).and_return(project)
        att
      end

      it 'does not award the achievement' do
        described_class.check_conditions_for(attachment)
        expect(user.awarded?(described_class)).to be false
      end
    end

    context 'when already awarded' do
      let(:attachment) do
        att = Attachment.new(filename: 'test.png', author: user, container: project, content_type: 'image/png')
        allow(att).to receive(:image?).and_return(true)
        allow(att).to receive(:project).and_return(project)
        att
      end

      it 'does not award twice' do
        described_class.check_conditions_for(attachment)

        expect {
          described_class.check_conditions_for(attachment)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
