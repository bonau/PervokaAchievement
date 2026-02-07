require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :issues, :projects, :trackers,
           :issue_statuses, :enumerations, :members, :member_roles, :roles

  def setup
    @user = User.find(2)
    User.current = @user
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    User.current = nil
  end

  test "issue should trigger achievement check on save" do
    issue = issues(:issues_001)
    issue.assigned_to = @user

    assert_nothing_raised do
      issue.save!
    end
  end

  test "saving issue with assigned user triggers FirstLoveAchievement" do
    issue = issues(:issues_001)
    issue.init_journal(@user)
    issue.assigned_to = @user
    issue.save!

    assert @user.awarded?(FirstLoveAchievement),
           "Saving issue with assignment should trigger FirstLoveAchievement"
  end
end
