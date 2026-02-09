require File.expand_path('../../test_helper', __FILE__)

class AttachmentPatchTest < ActiveSupport::TestCase
  fixtures :users, :projects, :attachments

  def setup
    @attachment = Attachment.find(1)
    @user = User.find(2)
  end

  def test_attachment_should_respond_to_check_achievement
    assert_respond_to @attachment, :check_achievement
  end

  def test_check_achievement_should_be_called_after_save
    attachment = Attachment.new(
      filename: 'test.png',
      author: @user,
      container: Project.find(1),
      content_type: 'image/png'
    )
    
    attachment.expects(:check_achievement).at_least_once
    attachment.stubs(:files_to_final_location)
    attachment.save!
  end

  def test_check_achievement_should_call_attach_a_picture_achievement
    AttachAPictureAchievement.expects(:check_conditions_for).with(@attachment)
    @attachment.check_achievement
  end
end
