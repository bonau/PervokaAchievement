require File.expand_path('../../test_helper', __FILE__)

class ProjectPatchTest < ActiveSupport::TestCase
  fixtures :users, :projects

  def setup
    @project = Project.find(1)
    @user = User.find(2)
    User.current = @user
  end

  def teardown
    User.current = nil
  end

  def test_project_should_have_old_close_method
    assert_respond_to @project, :old_close
  end

  def test_project_should_have_old_reopen_method
    assert_respond_to @project, :old_reopen
  end

  def test_close_should_call_close_project_achievement
    CloseProjectAchievement.expects(:check_conditions_for).with(@project)
    @project.close
  end

  def test_reopen_should_call_it_must_be_kidding_achievement
    @project.status = Project::STATUS_CLOSED
    @project.save!
    
    ItMustBeKiddingAchievement.expects(:check_conditions_for).with(@project)
    @project.reopen
  end

  def test_close_should_change_project_status
    @project.close
    @project.reload
    assert_equal Project::STATUS_CLOSED, @project.status
  end

  def test_reopen_should_change_project_status
    @project.status = Project::STATUS_CLOSED
    @project.save!
    
    @project.reopen
    @project.reload
    assert_equal Project::STATUS_ACTIVE, @project.status
  end
end
