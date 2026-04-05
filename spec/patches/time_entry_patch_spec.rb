require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::TimeEntryPatch do
  it 'is prepended to TimeEntry' do
    expect(TimeEntry < described_class).to be_truthy
  end

  it 'adds check_achievement callback' do
    expect(TimeEntry.new).to respond_to(:check_achievement)
  end
end
