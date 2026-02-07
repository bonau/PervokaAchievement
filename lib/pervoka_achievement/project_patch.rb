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
          if status == Project::STATUS_CLOSED
            CloseProjectAchievement.check_conditions_for(self)
          elsif status == Project::STATUS_ACTIVE && saved_change_to_status?
            ItMustBeKiddingAchievement.check_conditions_for(self)
          end
        end
      end
    end
  end
end
