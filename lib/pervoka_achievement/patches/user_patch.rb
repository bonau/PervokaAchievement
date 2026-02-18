module PervokaAchievement
  module Patches
    module UserPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_many :achievements
        end
      end

      module ClassMethods
      end
      module InstanceMethods
        def awarded?(achievement)
          achievements.count(:conditions => { :type => achievement }) > 0
        end

        def award(achievement)
          achievement = achievement.create(user: self)
        end
      end
    end
  end
end
