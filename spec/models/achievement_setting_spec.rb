require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AchievementSetting, type: :model do
  let(:achievement_class) { CreateFirstIssueAchievement }

  after { AchievementSetting.delete_all }

  describe 'validations' do
    it 'is valid with an achievement_type' do
      setting = AchievementSetting.new(achievement_type: achievement_class.name)
      expect(setting).to be_valid
    end

    it 'requires achievement_type' do
      setting = AchievementSetting.new(achievement_type: nil)
      expect(setting).not_to be_valid
      expect(setting.errors[:achievement_type]).not_to be_empty
    end

    it 'requires unique achievement_type' do
      AchievementSetting.create!(achievement_type: achievement_class.name)
      duplicate = AchievementSetting.new(achievement_type: achievement_class.name)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:achievement_type]).to include('has already been taken')
    end

    it 'requires enabled to be boolean' do
      setting = AchievementSetting.new(achievement_type: achievement_class.name, enabled: nil)
      expect(setting).not_to be_valid
      expect(setting.errors[:enabled]).to include('is not included in the list')
    end
  end

  describe '.for' do
    it 'returns existing setting when present' do
      existing = AchievementSetting.create!(achievement_type: achievement_class.name, enabled: false)
      result = AchievementSetting.for(achievement_class)
      expect(result).to eq existing
    end

    it 'returns a new unsaved record when no setting exists' do
      result = AchievementSetting.for(achievement_class)
      expect(result).to be_a(AchievementSetting)
      expect(result).to be_new_record
      expect(result.achievement_type).to eq achievement_class.name
    end
  end

  describe '.enabled?' do
    it 'returns true when no setting row exists' do
      expect(AchievementSetting.enabled?(achievement_class)).to be true
    end

    it 'returns true when setting is enabled' do
      AchievementSetting.create!(achievement_type: achievement_class.name, enabled: true)
      expect(AchievementSetting.enabled?(achievement_class)).to be true
    end

    it 'returns false when setting is disabled' do
      AchievementSetting.create!(achievement_type: achievement_class.name, enabled: false)
      expect(AchievementSetting.enabled?(achievement_class)).to be false
    end
  end

  describe 'custom_points' do
    it 'accepts a custom_points value' do
      setting = AchievementSetting.create!(achievement_type: achievement_class.name, custom_points: 50)
      expect(setting.custom_points).to eq 50
    end

    it 'allows nil custom_points' do
      setting = AchievementSetting.create!(achievement_type: achievement_class.name, custom_points: nil)
      expect(setting.custom_points).to be_nil
    end
  end

  describe '#display_text' do
    it 'returns custom text when present' do
      setting = AchievementSetting.new(
        achievement_type: achievement_class.name,
        custom_title: 'My Custom Title'
      )
      expect(setting.display_text(:title, 'achievement.create_first_issue_achievement.title')).to eq 'My Custom Title'
    end

    it 'falls back to i18n when custom text is nil' do
      setting = AchievementSetting.new(
        achievement_type: achievement_class.name,
        custom_title: nil
      )
      expected = I18n.t('achievement.create_first_issue_achievement.title')
      expect(setting.display_text(:title, 'achievement.create_first_issue_achievement.title')).to eq expected
    end

    it 'falls back to i18n when custom text is blank' do
      setting = AchievementSetting.new(
        achievement_type: achievement_class.name,
        custom_title: '   '
      )
      expected = I18n.t('achievement.create_first_issue_achievement.title')
      expect(setting.display_text(:title, 'achievement.create_first_issue_achievement.title')).to eq expected
    end
  end
end
