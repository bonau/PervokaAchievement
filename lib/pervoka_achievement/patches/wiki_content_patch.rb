module PervokaAchievement
  module Patches
    module WikiContentPatch
      extend ActiveSupport::Concern

      prepended do
        after_save :check_achievement
      end

      def check_achievement
        WikiEditorAchievement.check_conditions_for(self)
      end
    end
  end
end
