module PervokaAchievement
  module Patches
    module ProjectPatch
      def self.included(base)
        base.prepend(InstanceMethods)
      end

      module InstanceMethods
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
end
