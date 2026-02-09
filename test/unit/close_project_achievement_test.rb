require File.expand_path('../../test_helper', __FILE__)

class CloseProjectAchievementTest < ActiveSupport::TestCase
  fixtures :users, :projects

  def setup
    @user = User.find(2)
    User.current = @user
    @project = Project.find(1)
  end

  def teardown
    User.current = nil
  end

  def test_should_be_registered
    assert Achievement.registered_achievements.include?(CloseProjectAchievement)
  end

  def test_should_award_when_project_is_closed
    @user.achievements.where(type: 'CloseProjectAchievement').destroy_all
    
    @project.status = Project::STATUS_CLOSED
    @project.save!
    
    CloseProjectAchievement.check_conditions_for(@project)
    
    assert @user.awarded?(CloseProjectAchievement)
  end

  def test_should_not_award_when_project_is_active
    @user.achievements.where(type: 'CloseProjectAchievement').destroy_all
    
    @project.status = Project::STATUS_ACTIVE
    @project.save!
    
    CloseProjectAchievement.check_conditions_for(@project)
    
    assert_not @user.awarded?(CloseProjectAchievement)
  end

  def test_should_not_award_twice
    @user.achievements.where(type: 'CloseProjectAchievement').destroy_all
    
    @project.status = Project::STATUS_CLOSED
    @project.save!
    
    CloseProjectAchievement.check_conditions_for(@project)
    initial_count = @user.achievements.where(type: 'CloseProjectAchievement').count
    
    CloseProjectAchievement.check_conditions_for(@project)
    final_count = @user.achievements.where(type: 'CloseProjectAchievement').count
    
    assert_equal initial_count, final_count
  end
end
