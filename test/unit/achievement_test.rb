require File.expand_path('../../test_helper', __FILE__)

class AchievementTest < ActiveSupport::TestCase
  def test_user_should_not_be_nil
    achievement = Achievement.new
    assert !achievement.save
  end
end
