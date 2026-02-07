require File.expand_path('../../test_helper', __FILE__)

class AchievementTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses

  def setup
    @user = User.find(2) # existing fixture user
    # Ensure user has patches loaded
    ActionMailer::Base.deliveries.clear
  end

  test "should not save achievement without user" do
    achievement = Achievement.new
    assert_not achievement.save, "Saved achievement without a user"
  end

  test "should save achievement with valid user" do
    achievement = Achievement.new(user: @user, type: 'FirstLoveAchievement')
    assert achievement.save, "Could not save achievement with valid user"
  end

  test "should belong to user" do
    achievement = Achievement.new(user: @user, type: 'FirstLoveAchievement')
    achievement.save!
    assert_equal @user, achievement.user
  end

  test "should set timestamps on create" do
    achievement = Achievement.create!(user: @user, type: 'FirstLoveAchievement')
    assert_not_nil achievement.created_at
    assert_not_nil achievement.updated_at
  end

  test "parameter_name returns underscored class name" do
    assert_equal "achievement", Achievement.parameter_name
    assert_equal "first_love_achievement", FirstLoveAchievement.parameter_name
    assert_equal "close_project_achievement", CloseProjectAchievement.parameter_name
  end

  test "locale_prefix returns correct i18n key" do
    assert_equal "achievement.first_love_achievement", FirstLoveAchievement.locale_prefix
    assert_equal "achievement.first_love_achievement.title", FirstLoveAchievement.locale_prefix(:title)
    assert_equal "achievement.first_love_achievement.description", FirstLoveAchievement.locale_prefix(:description)
  end

  test "instance locale_prefix delegates to class method" do
    achievement = FirstLoveAchievement.new(user: @user)
    assert_equal "achievement.first_love_achievement.title", achievement.locale_prefix(:title)
  end

  test "registered_achievements includes all subclasses" do
    registered = Achievement.registered_achievements.map(&:name)
    assert_includes registered, "FirstLoveAchievement"
    assert_includes registered, "CloseProjectAchievement"
    assert_includes registered, "ItMustBeKiddingAchievement"
    assert_includes registered, "AttachAPictureAchievement"
  end

  test "should send email on creation" do
    achievement = Achievement.create!(user: @user, type: 'FirstLoveAchievement')
    assert_not_equal 0, ActionMailer::Base.deliveries.size, "No email was sent on achievement creation"
  end
end
