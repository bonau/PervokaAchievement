require File.expand_path('../../test_helper', __FILE__)

class AttachAPictureAchievementTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :projects

  def setup
    @user = User.find(2)
    ActionMailer::Base.deliveries.clear
  end

  test "should inherit from Achievement" do
    assert AttachAPictureAchievement < Achievement
  end

  test "parameter_name returns correct value" do
    assert_equal "attach_a_picture_achievement", AttachAPictureAchievement.parameter_name
  end
end
