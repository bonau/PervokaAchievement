module PervokaAchievement
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_save :check_project_achievements
        end
      end

      module InstanceMethods
        private

        def check_project_achievements
          if saved_change_to_status? && status == Project::STATUS_CLOSED
            CloseProjectAchievement.check_conditions_for(self)
          elsif saved_change_to_status? && status == Project::STATUS_ACTIVE
            ItMustBeKiddingAchievement.check_conditions_for(self)
          end
        end
      end
    end
  end
end
