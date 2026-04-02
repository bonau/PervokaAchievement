module PervokaAchievement
  module Patches
    module MemberPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_create :check_achievement
        end
      end

      module InstanceMethods
        def check_achievement
          TeamPlayerAchievement.check_conditions_for(self)
        end
      end
    end
  end
end
