require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase
  fixtures :users, :projects, :issues, :trackers, :issue_statuses

  def setup
    @issue = Issue.find(1)
    @user = User.find(2)
  end

  def test_issue_should_respond_to_check_achievement
    assert_respond_to @issue, :check_achievement
  end

  def test_check_achievement_should_be_called_after_save
    issue = Issue.new(
      project_id: 1,
      tracker_id: 1,
      subject: 'Test Issue',
      author_id: 1,
      assigned_to_id: @user.id,
      status_id: 1
    )
    
    issue.expects(:check_achievement).at_least_once
    issue.save!
  end

  def test_check_achievement_should_call_first_love_achievement
    @issue.assigned_to = @user
    
    FirstLoveAchievement.expects(:check_conditions_for).with(@user)
    @issue.check_achievement
  end

  def test_check_achievement_should_handle_nil_assigned_to
    @issue.assigned_to = nil
    
    assert_nothing_raised do
      @issue.check_achievement
    end
  end
end
