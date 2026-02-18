module PervokaAchievement
  module Patches
    module MailerPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
      end
      module InstanceMethods
        def achievement_unlocked(achievement)
          user = achievement.user
          set_language_if_valid user.language
          @achievement = l(achievement.class.locale_prefix)
          mail :to => user.mail,
            :subject => l(:"achievement.unlocked", :title => l(achievement.class.locale_prefix(:title)))
        end
      end
    end
  end
end
