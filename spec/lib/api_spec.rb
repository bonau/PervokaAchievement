require_relative '../spec_helper'

RSpec.describe PervokaAchievement::Api do
  let(:mail_double) { double(deliver_later: nil) }

  before { allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double) }
  after(:each) { described_class.reset! }

  let(:user) do
    User.find_or_create_by!(login: 'api_test') do |u|
      u.firstname = 'Api'
      u.lastname  = 'Test'
      u.mail      = 'api_test@example.com'
    end
  end

  describe '.register_achievement' do
    it 'creates a new achievement class' do
      klass = described_class.register_achievement(:code_reviewer, category: :social, tier: :silver, points: 20)
      expect(klass).to be < Achievement
      expect(klass.name).to eq('CodeReviewerAchievement')
    end

    it 'registers the class in Achievement.registered_achievements' do
      klass = described_class.register_achievement(:code_reviewer)
      expect(Achievement.registered_achievements).to include(klass)
    end

    it 'applies the provided options' do
      klass = described_class.register_achievement(:code_reviewer,
        category: :social, tier: :gold, points: 30,
        tags: [:skill, :teamwork], target_count: 5)

      expect(klass.category).to eq(:social)
      expect(klass.tier).to eq(:gold)
      expect(klass.points).to eq(30)
      expect(klass.tags).to eq([:skill, :teamwork])
      expect(klass.target_count).to eq(5)
    end

    it 'uses defaults when options are omitted' do
      klass = described_class.register_achievement(:simple_one)
      expect(klass.category).to eq(:general)
      expect(klass.tier).to eq(:bronze)
      expect(klass.points).to eq(10)
      expect(klass.tags).to eq([])
      expect(klass.target_count).to be_nil
    end

    it 'marks the class as external' do
      klass = described_class.register_achievement(:ext_one)
      expect(klass.external?).to be true
    end

    it 'raises on duplicate key' do
      described_class.register_achievement(:dup_test)
      expect { described_class.register_achievement(:dup_test) }
        .to raise_error(ArgumentError, /already registered/)
    end

    it 'raises if class name conflicts with existing constant' do
      expect { described_class.register_achievement(:first_love) }
        .to raise_error(ArgumentError, /already exists/)
    end
  end

  describe '.award' do
    before { described_class.register_achievement(:api_award_test, points: 15) }

    it 'awards the achievement to the user' do
      expect { described_class.award(:api_award_test, user) }
        .to change { user.achievements.count }.by(1)
    end

    it 'does not award twice' do
      described_class.award(:api_award_test, user)
      expect { described_class.award(:api_award_test, user) }
        .not_to change { user.achievements.count }
    end

    it 'returns nil when already awarded' do
      described_class.award(:api_award_test, user)
      expect(described_class.award(:api_award_test, user)).to be_nil
    end

    it 'respects achievement enabled setting' do
      AchievementSetting.create!(achievement_type: 'ApiAwardTestAchievement', enabled: false)
      expect { described_class.award(:api_award_test, user) }
        .not_to change { user.achievements.count }
    end
  end

  describe '.increment_progress' do
    before { described_class.register_achievement(:progress_api_test, target_count: 3) }

    it 'increments and awards when target is reached' do
      3.times { described_class.increment_progress(:progress_api_test, user) }
      expect(user.awarded?(ProgressApiTestAchievement)).to be true
    end

    it 'does not award before target is reached' do
      2.times { described_class.increment_progress(:progress_api_test, user) }
      expect(user.awarded?(ProgressApiTestAchievement)).to be false
    end
  end

  describe '.on / .fire_event' do
    it 'delivers event to subscribers' do
      payloads = []
      described_class.on(:achievement_unlocked) { |p| payloads << p }

      described_class.register_achievement(:event_test)
      described_class.award(:event_test, user)

      expect(payloads.size).to eq(1)
      expect(payloads.first[:user]).to eq(user)
      expect(payloads.first[:achievement_class].name).to eq('EventTestAchievement')
    end

    it 'does not raise when handler errors' do
      described_class.on(:achievement_unlocked) { raise 'boom' }
      described_class.register_achievement(:safe_event_test)

      expect { described_class.award(:safe_event_test, user) }.not_to raise_error
    end

    it 'supports multiple subscribers' do
      counts = [0, 0]
      described_class.on(:achievement_unlocked) { counts[0] += 1 }
      described_class.on(:achievement_unlocked) { counts[1] += 1 }

      described_class.register_achievement(:multi_sub_test)
      described_class.award(:multi_sub_test, user)

      expect(counts).to eq([1, 1])
    end
  end

  describe '.registered? / .registered_keys' do
    it 'tracks registered keys' do
      described_class.register_achievement(:key_test)
      expect(described_class.registered?(:key_test)).to be true
      expect(described_class.registered?(:unknown)).to be false
      expect(described_class.registered_keys).to include(:key_test)
    end
  end

  describe '.reset!' do
    it 'clears all external achievements' do
      described_class.register_achievement(:reset_test)
      described_class.reset!
      expect(described_class.registered_keys).to be_empty
      expect(Achievement.registered_achievements.map(&:name)).not_to include('ResetTestAchievement')
      expect(Object.const_defined?('ResetTestAchievement')).to be false
    end
  end
end
