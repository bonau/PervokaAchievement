module PervokaAchievement
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_save :check_achievement
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def check_achievement
          return unless saved_change_to_assigned_to_id?

          FirstLoveAchievement.check_conditions_for(self.assigned_to)
        end
      end
    end
  end
end
