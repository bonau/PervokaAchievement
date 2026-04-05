module PervokaAchievement
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      prepended do
        after_save :check_achievement
      end

      def check_achievement
        if saved_change_to_assigned_to_id?
          FirstLoveAchievement.check_conditions_for(self.assigned_to)
          SelfAssignedAchievement.check_conditions_for(self)
        end

        if previously_new_record?
          CreateFirstIssueAchievement.check_conditions_for(self)
          BugHunterAchievement.check_conditions_for(self)
          MultiTrackerAchievement.check_conditions_for(self)
        end

        if saved_change_to_status_id? && closed?
          ResolveFirstIssueAchievement.check_conditions_for(self)
          SpeedRunnerAchievement.check_conditions_for(self)
          EarlyBirdAchievement.check_conditions_for(self)
          LongHaulAchievement.check_conditions_for(self)
          PriorityExpertAchievement.check_conditions_for(self)
        end

        NightOwlAchievement.check_conditions_for(self)
        WeekendWarriorAchievement.check_conditions_for(self)
      end
    end
  end
end
