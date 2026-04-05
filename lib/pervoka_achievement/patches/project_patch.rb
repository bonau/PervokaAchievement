module PervokaAchievement
  module Patches
    module ProjectPatch
      extend ActiveSupport::Concern

      def close
        result = super
        CloseProjectAchievement.check_conditions_for(self)
        result
      end

      def reopen
        result = super
        ItMustBeKiddingAchievement.check_conditions_for(self)
        result
      end
    end
  end
end
