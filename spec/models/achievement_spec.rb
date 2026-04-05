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

  describe '.points' do
    it 'returns a default of 10 for the base class' do
      expect(Achievement.points).to eq 10
    end

    it 'returns specific points for SpeedRunnerAchievement' do
      expect(SpeedRunnerAchievement.points).to eq 25
    end

    it 'returns specific points for TeamPlayerAchievement' do
      expect(TeamPlayerAchievement.points).to eq 20
    end
  end

  describe '.effective_points' do
    after { AchievementSetting.where(achievement_type: 'FirstLoveAchievement').delete_all }

    it 'returns code-defined points when no custom setting exists' do
      expect(FirstLoveAchievement.effective_points).to eq FirstLoveAchievement.points
    end

    it 'returns custom points when setting exists' do
      AchievementSetting.create!(achievement_type: 'FirstLoveAchievement', custom_points: 50)
      expect(FirstLoveAchievement.effective_points).to eq 50
    end

    it 'falls back to code-defined points when custom_points is nil' do
      AchievementSetting.create!(achievement_type: 'FirstLoveAchievement', custom_points: nil)
      expect(FirstLoveAchievement.effective_points).to eq FirstLoveAchievement.points
    end
  end

  describe '.tags' do
    it 'returns empty array for the base class' do
      expect(Achievement.tags).to eq []
    end

    it 'returns [:milestone] for CreateFirstIssueAchievement' do
      expect(CreateFirstIssueAchievement.tags).to eq [:milestone]
    end

    it 'returns [:fun, :skill] for SpeedRunnerAchievement' do
      expect(SpeedRunnerAchievement.tags).to eq [:fun, :skill]
    end

    it 'returns [:teamwork] for TeamPlayerAchievement' do
      expect(TeamPlayerAchievement.tags).to eq [:teamwork]
    end

    it 'only contains valid tags from TAGS constant' do
      Achievement.registered_achievements.each do |klass|
        klass.tags.each do |tag|
          expect(Achievement::TAGS).to include(tag), "#{klass.name} has invalid tag :#{tag}"
        end
      end
    end
  end

  describe '.all_tags' do
    it 'returns all defined tag types' do
      expect(Achievement.all_tags).to eq [:milestone, :exploratory, :fun, :skill, :teamwork]
    end

    it 'is frozen' do
      expect(Achievement.all_tags).to be_frozen
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

    it 'does not award when achievement is disabled' do
      AchievementSetting.create!(achievement_type: 'Achievement', enabled: false)

      expect {
        Achievement.check_conditions_for(user) { true }
      }.not_to change { user.achievements.count }

      AchievementSetting.where(achievement_type: 'Achievement').delete_all
    end

    it 'awards normally when no setting row exists (default enabled)' do
      mail_double = double(deliver_later: nil)
      allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

      AchievementSetting.where(achievement_type: 'Achievement').delete_all

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
