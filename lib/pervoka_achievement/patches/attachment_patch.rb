module PervokaAchievement
  module Patches
    module AttachmentPatch
      extend ActiveSupport::Concern

      prepended do
        after_save :check_achievement
      end

      def check_achievement
        AttachAPictureAchievement.check_conditions_for(self)
      end
    end
  end
end
