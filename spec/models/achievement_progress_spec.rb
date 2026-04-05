require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AchievementProgress, type: :model do
  fixtures :users

  let(:user) { User.find(2) }

  describe 'validations' do
    it 'requires achievement_type' do
      progress = AchievementProgress.new(user: user, achievement_type: nil)
      expect(progress).not_to be_valid
    end

    it 'is valid with user and achievement_type' do
      progress = AchievementProgress.new(user: user, achievement_type: 'SomeAchievement')
      expect(progress).to be_valid
    end

    it 'enforces uniqueness of user_id scoped to achievement_type' do
      AchievementProgress.create!(user: user, achievement_type: 'TestAchievement', current_count: 1)
      duplicate = AchievementProgress.new(user: user, achievement_type: 'TestAchievement')
      expect(duplicate).not_to be_valid
      AchievementProgress.where(user: user, achievement_type: 'TestAchievement').delete_all
    end
  end

  describe '.for' do
    after { AchievementProgress.where(user: user).delete_all }

    it 'returns an existing record if one exists' do
      existing = AchievementProgress.create!(user: user, achievement_type: 'FirstLoveAchievement', current_count: 3)
      result = AchievementProgress.for(user, FirstLoveAchievement)
      expect(result.id).to eq existing.id
      expect(result.current_count).to eq 3
    end

    it 'returns a new record if none exists' do
      result = AchievementProgress.for(user, FirstLoveAchievement)
      expect(result).to be_new_record
      expect(result.achievement_type).to eq 'FirstLoveAchievement'
    end
  end

  describe '#percentage' do
    it 'returns 0 when target_count is nil' do
      progress = AchievementProgress.new(user: user, achievement_type: 'FirstLoveAchievement', current_count: 5)
      # FirstLoveAchievement.target_count is nil
      expect(progress.percentage).to eq 0
    end

    it 'calculates percentage correctly for known progress class' do
      # Create a temporary subclass with target_count
      stub_const('TestProgressAchievement', Class.new(Achievement) {
        def self.target_count; 10; end
      })
      progress = AchievementProgress.new(user: user, achievement_type: 'TestProgressAchievement', current_count: 3)
      expect(progress.percentage).to eq 30
    end

    it 'caps at 100 percent' do
      stub_const('TestProgressAchievement', Class.new(Achievement) {
        def self.target_count; 5; end
      })
      progress = AchievementProgress.new(user: user, achievement_type: 'TestProgressAchievement', current_count: 10)
      expect(progress.percentage).to eq 100
    end
  end

  describe '#complete?' do
    it 'returns false when target_count is nil' do
      progress = AchievementProgress.new(user: user, achievement_type: 'FirstLoveAchievement', current_count: 5)
      expect(progress.complete?).to be false
    end

    it 'returns true when current_count meets target' do
      stub_const('TestProgressAchievement', Class.new(Achievement) {
        def self.target_count; 5; end
      })
      progress = AchievementProgress.new(user: user, achievement_type: 'TestProgressAchievement', current_count: 5)
      expect(progress.complete?).to be true
    end

    it 'returns false when current_count is below target' do
      stub_const('TestProgressAchievement', Class.new(Achievement) {
        def self.target_count; 5; end
      })
      progress = AchievementProgress.new(user: user, achievement_type: 'TestProgressAchievement', current_count: 3)
      expect(progress.complete?).to be false
    end
  end
end
