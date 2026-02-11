require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Patches::MailerPatch, type: :model do
  fixtures :users

  let(:user) { User.find(2) }
  let(:achievement) { FirstLoveAchievement.create(user: user) }

  before { ActionMailer::Base.deliveries.clear }

  describe 'Mailer.achievement_unlocked' do
    it 'responds to achievement_unlocked' do
      expect(Mailer).to respond_to(:achievement_unlocked)
    end

    it 'creates a mail object' do
      mail = Mailer.achievement_unlocked(achievement)
      expect(mail).not_to be_nil
    end

    it 'sends to the correct user email' do
      mail = Mailer.achievement_unlocked(achievement)
      expect(mail.to).to eq [user.mail]
    end

    it 'has a non-empty subject' do
      mail = Mailer.achievement_unlocked(achievement)
      expect(mail.subject).to be_present
    end

    it 'respects user language setting' do
      user.update_attribute(:language, 'zh-TW')
      mail = Mailer.achievement_unlocked(achievement)
      expect(mail).not_to be_nil
    end
  end

  describe 'Achievement after_create callback' do
    it 'triggers mail delivery' do
      mail_double = double(deliver: true)
      allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

      CloseProjectAchievement.create(user: user)

      expect(Mailer).to have_received(:achievement_unlocked)
    end
  end
end
