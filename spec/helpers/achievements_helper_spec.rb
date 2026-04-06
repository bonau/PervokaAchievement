require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AchievementsHelper, type: :helper do
  fixtures :users

  let(:user) { User.find(2) }
  let(:achievement_class) { CreateFirstIssueAchievement }

  after { AchievementSetting.delete_all }

  describe '#achievement_text' do
    context 'with no custom text (no setting row)' do
      it 'returns the i18n default' do
        expected = I18n.t('achievement.create_first_issue_achievement.title')
        expect(helper.achievement_text(achievement_class, :title)).to eq expected
      end
    end

    context 'with custom text set' do
      before do
        AchievementSetting.create!(
          achievement_type: achievement_class.name,
          custom_title: 'Custom Title',
          custom_description: 'Custom Desc',
          custom_quote: 'Custom Quote'
        )
      end

      it 'returns custom title' do
        expect(helper.achievement_text(achievement_class, :title)).to eq 'Custom Title'
      end

      it 'returns custom description' do
        expect(helper.achievement_text(achievement_class, :description)).to eq 'Custom Desc'
      end

      it 'returns custom quote' do
        expect(helper.achievement_text(achievement_class, :quote)).to eq 'Custom Quote'
      end
    end

    context 'with blank custom text' do
      before do
        AchievementSetting.create!(
          achievement_type: achievement_class.name,
          custom_title: '   '
        )
      end

      it 'falls back to i18n default' do
        expected = I18n.t('achievement.create_first_issue_achievement.title')
        expect(helper.achievement_text(achievement_class, :title)).to eq expected
      end
    end

    context 'with an achievement instance' do
      it 'extracts the class and returns i18n default' do
        mail_double = double(deliver_later: nil)
        allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

        instance = achievement_class.create!(user: user)
        expected = I18n.t('achievement.create_first_issue_achievement.title')
        expect(helper.achievement_text(instance, :title)).to eq expected

        instance.destroy
      end
    end
  end

  describe '#achievement_icon' do
    it 'returns an img tag with correct alt text' do
      html = helper.achievement_icon(achievement_class)
      expect(html).to include('<img')
      expect(html).to include('alt=')
      expect(html).to include('create_first_issue')
    end

    it 'accepts a class argument' do
      html = helper.achievement_icon(achievement_class, size: 64)
      expect(html).to include('width="64"')
      expect(html).to include('height="64"')
    end

    it 'accepts an instance argument' do
      mail_double = double(deliver_later: nil)
      allow(Mailer).to receive(:achievement_unlocked).and_return(mail_double)

      instance = achievement_class.create!(user: user)
      html = helper.achievement_icon(instance)
      expect(html).to include('create_first_issue')

      instance.destroy
    end

    it 'uses default size of 32' do
      html = helper.achievement_icon(achievement_class)
      expect(html).to include('width="32"')
      expect(html).to include('height="32"')
    end
  end
end
