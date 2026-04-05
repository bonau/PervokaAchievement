module PervokaAchievement
  module Patches
    module TimeEntryPatch
      extend ActiveSupport::Concern

      prepended do
        after_create :check_achievement
      end

      def check_achievement
        TimeTrackerAchievement.check_conditions_for(self)
      end
    end
  end
end
