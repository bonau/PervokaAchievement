require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe Achievement, type: :model do
  fixtures :users

  let(:user) { User.find(2) }

  describe 'validations' do
    it 'requires a user' do
      achievement = Achievement.new
      expect(achievement).not_to be_valid
      expect(achievement.save).to be false
    end

    it 'is valid with a user' do
      achievement = Achievement.new(user: user)
      expect(achievement).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      achievement = Achievement.new(user: user)
      expect(achievement.user).to eq user
    end
  end

  describe '.registered_achievements' do
    it 'responds to registered_achievements' do
      expect(Achievement).to respond_to(:registered_achievements)
    end

    it 'is an Array' do
      expect(Achievement.registered_achievements).to be_a(Array)
    end

    it 'includes all subclasses' do
      expect(Achievement.registered_achievements).to include(
        FirstLoveAchievement,
        AttachAPictureAchievement,
        CloseProjectAchievement,
        ItMustBeKiddingAchievement
      )
    end
  end

  describe '.category' do
    it 'returns :general for the base class' do
      expect(Achievement.category).to eq :general
    end

    it 'returns :issue for FirstLoveAchievement' do
      expect(FirstLoveAchievement.category).to eq :issue
    end

    it 'returns :project for CloseProjectAchievement' do
      expect(CloseProjectAchievement.category).to eq :project
    end

    it 'returns :project for ItMustBeKiddingAchievement' do
      expect(ItMustBeKiddingAchievement.category).to eq :project
    end

    it 'returns :social for AttachAPictureAchievement' do
      expect(AttachAPictureAchievement.category).to eq :social
    end
  end

  describe '.categories' do
    it 'returns the ordered list of all categories' do
      expect(Achievement.categories).to eq [:issue, :project, :wiki, :social, :general]
    end

    it 'is frozen' do
      expect(Achievement.categories).to be_frozen
    end
  end

  describe '.parameter_name' do
    it 'returns the underscored class name' do
      expect(FirstLoveAchievement.parameter_name).to eq 'first_love_achievement'
      expect(AttachAPictureAchievement.parameter_name).to eq 'attach_a_picture_achievement'
    end
  end

  describe '.locale_prefix' do
    it 'returns base prefix without argument' do
      expect(FirstLoveAchievement.locale_prefix).to eq 'achievement.first_love_achievement'
    end

    it 'appends name when given' do
      expect(FirstLoveAchievement.locale_prefix(:title)).to eq 'achievement.first_love_achievement.title'
    end
  end

  describe '#locale_prefix' do
    let(:achievement) { FirstLoveAchievement.new(user: user) }

    it 'delegates to class method' do
      expect(achievement.locale_prefix).to eq 'achievement.first_love_achievement'
      expect(achievement.locale_prefix(:description)).to eq 'achievement.first_love_achievement.description'
    end
  end

  describe '.check_conditions_for' do
    before { user.achievements.destroy_all }

    it 'does not raise when user is nil' do
      expect { Achievement.check_conditions_for(nil) { true } }.not_to raise_error
    end

    # Test the base Achievement mechanism (not a subclass that overrides the method)
    it 'does not award when condition block returns false' do
      expect {
        Achievement.check_conditions_for(user) { false }
      }.not_to change { user.achievements.count }
    end

    it 'awards when condition block returns true' do
      mail_double = double(deliver_later: nil)
      allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

      expect {
        Achievement.check_conditions_for(user) { true }
      }.to change { user.achievements.count }.by(1)
    end
  end

  describe '#deliver_mail' do
    it 'is called after create' do
      mail_double = double(deliver_later: nil)
      allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

      Achievement.create(user: user)

      expect(Mailer).to have_received(:achievement_unlocked)
    end
  end
end
