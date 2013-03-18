require File.expand_path('../../test_helper', __FILE__)

class AchievementsControllerTest < ActionController::TestCase
  test "should_get_index" do
    get :index
    assert_response :success
  end
end
