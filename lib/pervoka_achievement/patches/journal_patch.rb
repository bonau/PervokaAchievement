module PervokaAchievement
  module Patches
    module JournalPatch
      extend ActiveSupport::Concern

      prepended do
        after_create :check_achievement
      end

      def check_achievement
        FirstCommentAchievement.check_conditions_for(self)
      end
    end
  end
end
