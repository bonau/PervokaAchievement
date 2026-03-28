module PervokaAchievement
  module Patches
    module UserPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_many :achievements
        end
      end

      module ClassMethods
      end
      module InstanceMethods
        def awarded?(achievement)
          achievements.where(type: achievement.to_s).exists?
        end

        def award(achievement)
          achievement = achievement.create(user: self)
        end
      end
    end
  end
end
