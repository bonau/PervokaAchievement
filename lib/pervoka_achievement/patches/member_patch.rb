module PervokaAchievement
  module Patches
    module MemberPatch
      extend ActiveSupport::Concern

      prepended do
        after_create :check_achievement
      end

      def check_achievement
        TeamPlayerAchievement.check_conditions_for(self)
      end
    end
  end
end
