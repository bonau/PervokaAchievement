require File.expand_path('../../test_helper', __FILE__)

class ItMustBeKiddingAchievementTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :projects

  def setup
    @user = User.find(2)
    User.current = @user
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    User.current = nil
  end

  test "should inherit from Achievement" do
    assert ItMustBeKiddingAchievement < Achievement
  end

  test "parameter_name returns correct value" do
    assert_equal "it_must_be_kidding_achievement", ItMustBeKiddingAchievement.parameter_name
  end
end
