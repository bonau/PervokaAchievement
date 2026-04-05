require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AchievementUserSetting, type: :model do
  fixtures :users

  let(:user) { User.find(2) }

  after { AchievementUserSetting.delete_all }

  describe 'validations' do
    it 'is valid with a user' do
      setting = AchievementUserSetting.new(user: user)
      expect(setting).to be_valid
    end

    it 'requires a user' do
      setting = AchievementUserSetting.new(user_id: nil)
      expect(setting).not_to be_valid
    end

    it 'requires unique user_id' do
      AchievementUserSetting.create!(user: user)
      duplicate = AchievementUserSetting.new(user: user)
      expect(duplicate).not_to be_valid
    end
  end

  describe '.for' do
    it 'returns existing setting when present' do
      existing = AchievementUserSetting.create!(user: user, public_profile: true)
      result = AchievementUserSetting.for(user)
      expect(result).to eq existing
    end

    it 'returns a new unsaved record when no setting exists' do
      result = AchievementUserSetting.for(user)
      expect(result).to be_new_record
      expect(result.user_id).to eq user.id
    end
  end

  describe '.public_profile?' do
    it 'returns false when no setting exists' do
      expect(AchievementUserSetting.public_profile?(user)).to be false
    end

    it 'returns false when public_profile is false' do
      AchievementUserSetting.create!(user: user, public_profile: false)
      expect(AchievementUserSetting.public_profile?(user)).to be false
    end

    it 'returns true when public_profile is true' do
      AchievementUserSetting.create!(user: user, public_profile: true)
      expect(AchievementUserSetting.public_profile?(user)).to be true
    end
  end

  describe 'defaults' do
    it 'defaults public_profile to false' do
      setting = AchievementUserSetting.new(user: user)
      expect(setting.public_profile?).to be false
    end
  end
end
