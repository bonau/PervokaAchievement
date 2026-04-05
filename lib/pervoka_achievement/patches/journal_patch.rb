module PervokaAchievement
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_create :check_achievement
        end
      end

      module InstanceMethods
        def check_achievement
          FirstCommentAchievement.check_conditions_for(self)
        end
      end
    end
  end
end
