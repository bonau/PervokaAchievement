require File.expand_path('../../test_helper', __FILE__)

class AchievementTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @user = User.find(2)
  end

  def test_user_should_not_be_nil
    achievement = Achievement.new
    assert !achievement.save
  end

  def test_achievement_should_belong_to_user
    achievement = Achievement.new(user: @user)
    assert_equal @user, achievement.user
  end

  def test_achievement_should_be_valid_with_user
    achievement = Achievement.new(user: @user)
    assert achievement.valid?
  end

  def test_achievement_should_have_registered_achievements
    assert_respond_to Achievement, :registered_achievements
    assert_kind_of Array, Achievement.registered_achievements
  end

  def test_registered_achievements_should_include_subclasses
    assert Achievement.registered_achievements.include?(FirstLoveAchievement)
    assert Achievement.registered_achievements.include?(AttachAPictureAchievement)
    assert Achievement.registered_achievements.include?(CloseProjectAchievement)
    assert Achievement.registered_achievements.include?(ItMustBeKiddingAchievement)
  end

  def test_parameter_name_should_return_underscore_name
    assert_equal 'first_love_achievement', FirstLoveAchievement.parameter_name
    assert_equal 'attach_a_picture_achievement', AttachAPictureAchievement.parameter_name
  end

  def test_locale_prefix_class_method
    assert_equal 'achievement.first_love_achievement', FirstLoveAchievement.locale_prefix
    assert_equal 'achievement.first_love_achievement.title', FirstLoveAchievement.locale_prefix(:title)
  end

  def test_locale_prefix_instance_method
    achievement = FirstLoveAchievement.new(user: @user)
    assert_equal 'achievement.first_love_achievement', achievement.locale_prefix
    assert_equal 'achievement.first_love_achievement.description', achievement.locale_prefix(:description)
  end

  def test_check_conditions_for_should_not_award_without_user
    FirstLoveAchievement.check_conditions_for(nil) { true }
    # 不應該拋出錯誤
    assert true
  end

  def test_check_conditions_for_should_not_award_when_condition_fails
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    initial_count = @user.achievements.count
    
    FirstLoveAchievement.check_conditions_for(@user) { false }
    
    assert_equal initial_count, @user.achievements.count
  end

  def test_check_conditions_for_should_award_when_condition_passes
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    initial_count = @user.achievements.count
    
    FirstLoveAchievement.check_conditions_for(@user) { true }
    
    assert_equal initial_count + 1, @user.achievements.count
  end

  def test_deliver_mail_should_be_called_after_create
    Mailer.expects(:achievement_unlocked).returns(stub(deliver: true))
    Achievement.create(user: @user)
  end
end
