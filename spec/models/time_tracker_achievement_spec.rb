require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe TimeTrackerAchievement, type: :model do
  fixtures :users

  let(:user) { User.find(2) }

  it 'is registered' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :issue' do
    expect(described_class.category).to eq :issue
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    it 'awards on first time entry' do
      time_entry = double('TimeEntry', user: user)
      described_class.check_conditions_for(time_entry)
      expect(user.awarded?(described_class)).to be true
    end

    it 'does not award when user is not a User' do
      time_entry = double('TimeEntry', user: nil)
      described_class.check_conditions_for(time_entry)
      expect(user.awarded?(described_class)).to be false
    end
  end
end
