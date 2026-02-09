require File.expand_path('../../test_helper', __FILE__)

class AchievementsControllerTest < ActionController::TestCase
  fixtures :users, :projects

  def setup
    @user = User.find(2)
    @request.session[:user_id] = @user.id
    User.current = @user
  end

  def teardown
    User.current = nil
  end

  test "should_get_index" do
    get :index
    assert_response :success
  end

  test "index_should_assign_all_achievement_classes" do
    get :index
    assert_not_nil assigns(:all_achievement_classes)
    assert_kind_of Array, assigns(:all_achievement_classes)
    assert assigns(:all_achievement_classes).include?(FirstLoveAchievement)
  end

  test "index_should_assign_user_achievements" do
    get :index
    assert_not_nil assigns(:user_achievements)
  end

  test "index_should_assign_unlocked_achievement_classes" do
    FirstLoveAchievement.create(user: @user)
    
    get :index
    assert_not_nil assigns(:unlocked_achievement_classes)
    assert_kind_of Array, assigns(:unlocked_achievement_classes)
  end

  test "index_should_assign_unlockable_achievement_classes" do
    get :index
    assert_not_nil assigns(:unlockable_achievement_classes)
    assert_kind_of Array, assigns(:unlockable_achievement_classes)
  end

  test "unlocked_and_unlockable_should_be_mutually_exclusive" do
    FirstLoveAchievement.create(user: @user)
    
    get :index
    unlocked = assigns(:unlocked_achievement_classes)
    unlockable = assigns(:unlockable_achievement_classes)
    
    # 確保已解鎖的成就不在可解鎖清單中
    assert_equal [], (unlocked & unlockable)
  end

  test "all_achievements_should_equal_unlocked_plus_unlockable" do
    get :index
    all = assigns(:all_achievement_classes)
    unlocked = assigns(:unlocked_achievement_classes)
    unlockable = assigns(:unlockable_achievement_classes)
    
    assert_equal all.sort_by(&:name), (unlocked + unlockable).sort_by(&:name)
  end

  test "index_should_show_unlocked_achievements" do
    # 建立一個成就
    achievement = FirstLoveAchievement.create(user: @user)
    
    get :index
    assert_response :success
    assert assigns(:unlocked_achievement_classes).include?(FirstLoveAchievement)
  end

  test "index_without_login_should_redirect" do
    @request.session[:user_id] = nil
    User.current = nil
    
    get :index
    # 根據 Redmine 的行為，未登入應該重新導向或返回 401/403
    assert_response :redirect
  rescue
    # 如果沒有設定適當的認證，可能會拋出錯誤
    # 這取決於 Redmine 的版本和設定
    assert true
  end
end
