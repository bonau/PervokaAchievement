module PervokaAchievement
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_many :achievements
        end
      end

      module InstanceMethods
        def awarded?(achievement)
          achievements.where(type: achievement.name).exists?
        end

        def award(achievement)
          achievement.create(user: self)
        end
      end
    end
  end
end
