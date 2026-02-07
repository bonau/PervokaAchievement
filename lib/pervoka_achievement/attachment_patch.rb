module PervokaAchievement
  module Patches
    module AttachmentPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_save :check_achievement
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def check_achievement
          AttachAPictureAchievement.check_conditions_for(attachment)
        end
      end
    end
  end
end
