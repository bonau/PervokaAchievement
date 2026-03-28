require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::UserPatch, type: :model do
  fixtures :users

  let(:user) { User.find(2) }

  describe 'associations' do
    it 'adds has_many :achievements' do
      expect(user).to respond_to(:achievements)
    end
  end

  describe '#awarded?' do
    before { user.achievements.where(type: 'FirstLoveAchievement').destroy_all }

    it 'is defined on User' do
      expect(user).to respond_to(:awarded?)
    end

    it 'returns false when the user has not been awarded' do
      expect(user.awarded?(FirstLoveAchievement)).to be false
    end

    it 'returns true when the user has been awarded' do
      FirstLoveAchievement.create(user: user)
      expect(user.awarded?(FirstLoveAchievement)).to be true
    end
  end

  describe '#award' do
    before { user.achievements.where(type: 'FirstLoveAchievement').destroy_all }

    it 'is defined on User' do
      expect(user).to respond_to(:award)
    end

    it 'creates a new achievement record' do
      expect {
        user.award(FirstLoveAchievement)
      }.to change { user.achievements.count }.by(1)
    end

    it 'creates the correct achievement type' do
      user.award(FirstLoveAchievement)
      expect(user.achievements.where(type: 'FirstLoveAchievement')).to exist
    end
  end
end
