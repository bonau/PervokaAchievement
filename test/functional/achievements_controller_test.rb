require File.expand_path('../../test_helper', __FILE__)

class AchievementsControllerTest < ActionController::TestCase
  fixtures :users, :email_addresses

  def setup
    @user = User.find(2)
    @request.session[:user_id] = @user.id
    ActionMailer::Base.deliveries.clear
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "index assigns user achievements" do
    get :index
    assert_not_nil assigns(:user_achievements)
  end

  test "index assigns all achievement classes" do
    get :index
    assert_not_nil assigns(:all_achievement_classes)
    assert assigns(:all_achievement_classes).is_a?(Array)
  end

  test "index assigns unlockable achievement classes" do
    get :index
    assert_not_nil assigns(:unlockable_achievement_classes)
  end

  test "index shows unlocked achievements for current user" do
    # Award an achievement first
    @user.award(FirstLoveAchievement)

    get :index
    assert_response :success
    assert_includes assigns(:user_achievements).map(&:class), FirstLoveAchievement
  end

  test "index separates unlocked from unlockable" do
    @user.award(FirstLoveAchievement)

    get :index
    unlocked_classes = assigns(:unlocked_achievement_classes)
    unlockable_classes = assigns(:unlockable_achievement_classes)

    assert_includes unlocked_classes, FirstLoveAchievement
    assert_not_includes unlockable_classes, FirstLoveAchievement
  end

  test "should redirect to login when not authenticated" do
    @request.session[:user_id] = nil
    get :index
    assert_response :redirect
  end
end
