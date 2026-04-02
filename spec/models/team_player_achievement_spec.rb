require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe TeamPlayerAchievement, type: :model do
  fixtures :users, :projects, :roles, :members, :member_roles, :enabled_modules

  let(:user) { User.find(2) }

  it 'is registered in Achievement.registered_achievements' do
    expect(Achievement.registered_achievements).to include(described_class)
  end

  it 'has category :social' do
    expect(described_class.category).to eq :social
  end

  describe '.check_conditions_for' do
    before { user.achievements.where(type: described_class.name).destroy_all }

    context 'when user is member of 3+ active projects' do
      let(:member) do
        m = Member.new
        allow(m).to receive(:principal).and_return(user)
        m
      end

      it 'awards the achievement' do
        active_count = user.memberships.joins(:project)
                           .where(projects: { status: Project::STATUS_ACTIVE }).count
        skip "User has fewer than 3 active memberships (#{active_count})" if active_count < 3

        described_class.check_conditions_for(member)
        expect(user.awarded?(described_class)).to be true
      end
    end

    context 'when user is member of fewer than 3 projects' do
      let(:new_user) { User.find(1) }
      let(:member) do
        m = Member.new
        allow(m).to receive(:principal).and_return(new_user)
        m
      end

      before { new_user.achievements.where(type: described_class.name).destroy_all }

      it 'does not award the achievement if fewer than 3 active memberships' do
        active_count = new_user.memberships.joins(:project)
                               .where(projects: { status: Project::STATUS_ACTIVE }).count
        skip "User already has 3+ active memberships (#{active_count})" if active_count >= 3

        described_class.check_conditions_for(member)
        expect(new_user.awarded?(described_class)).to be false
      end
    end

    context 'when member principal is a Group' do
      let(:group) { Group.create!(lastname: 'TestGroup') }
      let(:member) do
        m = Member.new
        allow(m).to receive(:principal).and_return(group)
        m
      end

      it 'does not raise and does not award' do
        expect { described_class.check_conditions_for(member) }.not_to raise_error
      end
    end

    context 'when already awarded' do
      let(:member) do
        m = Member.new
        allow(m).to receive(:principal).and_return(user)
        m
      end

      before do
        active_count = user.memberships.joins(:project)
                           .where(projects: { status: Project::STATUS_ACTIVE }).count
        skip "User has fewer than 3 active memberships" if active_count < 3
        described_class.check_conditions_for(member)
      end

      it 'does not award twice' do
        expect {
          described_class.check_conditions_for(member)
        }.not_to change { user.achievements.where(type: described_class.name).count }
      end
    end
  end
end
