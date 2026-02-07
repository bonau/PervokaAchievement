require File.expand_path('../../test_helper', __FILE__)

class UserPatchTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses

  def setup
    @user = User.find(2)
    ActionMailer::Base.deliveries.clear
  end

  test "user should have achievements association" do
    assert_respond_to @user, :achievements
  end

  test "user should respond to awarded?" do
    assert_respond_to @user, :awarded?
  end

  test "user should respond to award" do
    assert_respond_to @user, :award
  end

  test "awarded? returns false when user has no achievement of that type" do
    assert_not @user.awarded?(FirstLoveAchievement),
               "User should not have FirstLoveAchievement initially"
  end

  test "award creates an achievement for the user" do
    initial_count = @user.achievements.count
    @user.award(FirstLoveAchievement)
    assert_equal initial_count + 1, @user.achievements.reload.count
  end

  test "awarded? returns true after awarding" do
    @user.award(FirstLoveAchievement)
    assert @user.awarded?(FirstLoveAchievement),
           "User should have FirstLoveAchievement after being awarded"
  end
end
