module PervokaAchievement
  module Patches
    module MailerPatch
      extend ActiveSupport::Concern

      def achievement_unlocked(user, achievement)
        set_language_if_valid user.language
        defaults = l(achievement.class.locale_prefix)
        setting = AchievementSetting.find_by(achievement_type: achievement.class.name)
        @achievement = defaults.merge(
          [:title, :description, :quote].each_with_object({}) do |f, h|
            v = setting&.send("custom_#{f}")
            h[f] = v if v.present?
          end
        )
        mail :to => user.mail,
          :subject => l(:"achievement.unlocked", :title => @achievement[:title])
      end
    end
  end
end
