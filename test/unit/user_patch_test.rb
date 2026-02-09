require File.expand_path('../../test_helper', __FILE__)

class UserPatchTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @user = User.find(2)
  end

  def test_user_should_have_achievements_association
    assert_respond_to @user, :achievements
  end

  def test_user_should_respond_to_awarded
    assert_respond_to @user, :awarded?
  end

  def test_user_should_respond_to_award
    assert_respond_to @user, :award
  end

  def test_awarded_should_return_false_when_no_achievement
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    assert_not @user.awarded?(FirstLoveAchievement)
  end

  def test_awarded_should_return_true_when_has_achievement
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    FirstLoveAchievement.create(user: @user)
    assert @user.awarded?(FirstLoveAchievement)
  end

  def test_award_should_create_achievement
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    initial_count = @user.achievements.count
    
    @user.award(FirstLoveAchievement)
    
    assert_equal initial_count + 1, @user.achievements.count
  end

  def test_award_should_create_correct_achievement_type
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    
    @user.award(FirstLoveAchievement)
    
    assert @user.achievements.where(type: 'FirstLoveAchievement').exists?
  end
end
