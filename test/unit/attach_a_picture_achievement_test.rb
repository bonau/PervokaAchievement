require File.expand_path('../../test_helper', __FILE__)

class AttachAPictureAchievementTest < ActiveSupport::TestCase
  fixtures :users, :projects, :attachments

  def setup
    @user = User.find(2)
    @project = Project.find(1)
  end

  def test_should_be_registered
    assert Achievement.registered_achievements.include?(AttachAPictureAchievement)
  end

  def test_should_award_when_user_attaches_image_to_project
    # 確保使用者尚未獲得此成就
    @user.achievements.where(type: 'AttachAPictureAchievement').destroy_all
    
    attachment = Attachment.new(
      filename: 'test.png',
      author: @user,
      container: @project,
      content_type: 'image/png'
    )
    
    # Mock image? 方法
    attachment.stubs(:image?).returns(true)
    
    AttachAPictureAchievement.check_conditions_for(attachment)
    
    assert @user.awarded?(AttachAPictureAchievement)
  end

  def test_should_not_award_when_attachment_is_not_image
    @user.achievements.where(type: 'AttachAPictureAchievement').destroy_all
    
    attachment = Attachment.new(
      filename: 'test.pdf',
      author: @user,
      container: @project,
      content_type: 'application/pdf'
    )
    
    attachment.stubs(:image?).returns(false)
    
    AttachAPictureAchievement.check_conditions_for(attachment)
    
    assert_not @user.awarded?(AttachAPictureAchievement)
  end

  def test_should_not_award_twice
    @user.achievements.where(type: 'AttachAPictureAchievement').destroy_all
    
    attachment = Attachment.new(
      filename: 'test.png',
      author: @user,
      container: @project,
      content_type: 'image/png'
    )
    
    attachment.stubs(:image?).returns(true)
    
    AttachAPictureAchievement.check_conditions_for(attachment)
    initial_count = @user.achievements.where(type: 'AttachAPictureAchievement').count
    
    AttachAPictureAchievement.check_conditions_for(attachment)
    final_count = @user.achievements.where(type: 'AttachAPictureAchievement').count
    
    assert_equal initial_count, final_count
  end
end
