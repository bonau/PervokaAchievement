module PervokaAchievement
  module Patches
    module AttachmentPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_create :check_achievement
        end
      end

      module InstanceMethods
        private

        def check_achievement
          AttachAPictureAchievement.check_conditions_for(self)
        end
      end
    end
  end
end
