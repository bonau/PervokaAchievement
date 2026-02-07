require File.expand_path('../../test_helper', __FILE__)

class CloseProjectAchievementTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :projects, :members, :member_roles, :roles

  def setup
    @user = User.find(2)
    User.current = @user
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    User.current = nil
  end

  test "should inherit from Achievement" do
    assert CloseProjectAchievement < Achievement
  end

  test "parameter_name returns correct value" do
    assert_equal "close_project_achievement", CloseProjectAchievement.parameter_name
  end
end
