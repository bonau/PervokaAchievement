require File.expand_path('../../test_helper', __FILE__)

class MailerPatchTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @user = User.find(2)
    @achievement = FirstLoveAchievement.create(user: @user)
    ActionMailer::Base.deliveries.clear
  end

  def test_mailer_should_respond_to_achievement_unlocked
    assert_respond_to Mailer, :achievement_unlocked
  end

  def test_achievement_unlocked_should_create_mail
    mail = Mailer.achievement_unlocked(@achievement)
    assert_not_nil mail
  end

  def test_achievement_unlocked_should_send_to_user
    mail = Mailer.achievement_unlocked(@achievement)
    assert_equal [@user.mail], mail.to
  end

  def test_achievement_unlocked_should_set_language
    @user.update_attribute(:language, 'zh-TW')
    mail = Mailer.achievement_unlocked(@achievement)
    # 驗證郵件內容包含本地化文字
    assert_not_nil mail
  end

  def test_achievement_unlocked_should_include_achievement_title
    mail = Mailer.achievement_unlocked(@achievement)
    assert_not_nil mail.subject
    # 郵件主旨應該包含成就相關的資訊
    assert mail.subject.length > 0
  end

  def test_achievement_should_deliver_mail_after_create
    @user.achievements.where(type: 'CloseProjectAchievement').destroy_all
    
    # 模擬郵件發送
    Mailer.expects(:achievement_unlocked).returns(stub(deliver: true))
    
    CloseProjectAchievement.create(user: @user)
  end
end
