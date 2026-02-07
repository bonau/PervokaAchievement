require File.expand_path('../../test_helper', __FILE__)

class FirstLoveAchievementTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :issues, :projects, :trackers, :issue_statuses,
           :enumerations, :members, :member_roles, :roles

  def setup
    @user = User.find(2)
    ActionMailer::Base.deliveries.clear
  end

  test "should inherit from Achievement" do
    assert FirstLoveAchievement < Achievement
  end

  test "parameter_name returns correct value" do
    assert_equal "first_love_achievement", FirstLoveAchievement.parameter_name
  end

  test "check_conditions_for awards when user is assigned to an issue" do
    # Assign an issue to the user
    issue = issues(:issues_001)
    issue.update!(assigned_to: @user)

    FirstLoveAchievement.check_conditions_for(@user)

    assert @user.awarded?(FirstLoveAchievement),
           "User should be awarded FirstLoveAchievement when assigned to an issue"
  end

  test "check_conditions_for does not award when user has no assigned issues" do
    # Make sure user has no assigned issues
    Issue.where(assigned_to_id: @user.id).update_all(assigned_to_id: nil)

    FirstLoveAchievement.check_conditions_for(@user)

    assert_not @user.awarded?(FirstLoveAchievement),
               "User should not be awarded FirstLoveAchievement without assigned issues"
  end

  test "check_conditions_for does not award twice" do
    issue = issues(:issues_001)
    issue.update!(assigned_to: @user)

    FirstLoveAchievement.check_conditions_for(@user)
    FirstLoveAchievement.check_conditions_for(@user)

    count = @user.achievements.where(type: 'FirstLoveAchievement').count
    assert_equal 1, count, "Achievement should only be awarded once"
  end

  test "check_conditions_for handles nil user gracefully" do
    assert_nothing_raised do
      FirstLoveAchievement.check_conditions_for(nil)
    end
  end
end
