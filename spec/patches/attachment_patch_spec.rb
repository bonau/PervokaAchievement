require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::AttachmentPatch, type: :model do
  fixtures :users, :projects, :attachments

  let(:attachment) { Attachment.find(1) }
  let(:user)       { User.find(2) }

  describe '#check_achievement' do
    it 'is defined on Attachment' do
      expect(attachment).to respond_to(:check_achievement)
    end

    it 'delegates to AttachAPictureAchievement.check_conditions_for with self' do
      expect(AttachAPictureAchievement).to receive(:check_conditions_for).with(attachment)
      attachment.check_achievement
    end
  end

  describe 'after_save callback' do
    it 'calls check_achievement' do
      new_attachment = Attachment.new(
        filename: 'test.png', author: user,
        container: Project.find(1), content_type: 'image/png'
      )
      allow(new_attachment).to receive(:files_to_final_location)

      expect(new_attachment).to receive(:check_achievement).at_least(:once)
      new_attachment.save!
    end
  end
end
