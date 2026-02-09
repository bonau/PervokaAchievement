require File.expand_path('../../test_helper', __FILE__)

class FirstLoveAchievementTest < ActiveSupport::TestCase
  fixtures :users, :projects, :issues, :trackers, :issue_statuses

  def setup
    @user = User.find(2)
  end

  def test_should_be_registered
    assert Achievement.registered_achievements.include?(FirstLoveAchievement)
  end

  def test_should_award_when_user_has_assigned_issue
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    
    # 建立一個指派給使用者的議題
    issue = Issue.create!(
      project_id: 1,
      tracker_id: 1,
      subject: 'Test Issue',
      author_id: 1,
      assigned_to_id: @user.id,
      status_id: 1
    )
    
    FirstLoveAchievement.check_conditions_for(@user)
    
    assert @user.awarded?(FirstLoveAchievement)
  end

  def test_should_not_award_when_user_has_no_assigned_issue
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    
    # 確保使用者沒有被指派的議題
    Issue.where(assigned_to_id: @user.id).destroy_all
    
    FirstLoveAchievement.check_conditions_for(@user)
    
    assert_not @user.awarded?(FirstLoveAchievement)
  end

  def test_should_not_award_twice
    @user.achievements.where(type: 'FirstLoveAchievement').destroy_all
    
    issue = Issue.create!(
      project_id: 1,
      tracker_id: 1,
      subject: 'Test Issue',
      author_id: 1,
      assigned_to_id: @user.id,
      status_id: 1
    )
    
    FirstLoveAchievement.check_conditions_for(@user)
    initial_count = @user.achievements.where(type: 'FirstLoveAchievement').count
    
    FirstLoveAchievement.check_conditions_for(@user)
    final_count = @user.achievements.where(type: 'FirstLoveAchievement').count
    
    assert_equal initial_count, final_count
  end
end
