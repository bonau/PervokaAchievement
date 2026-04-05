module PervokaAchievement
  module Patches
    module WikiContentPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_save :check_achievement
        end
      end

      module InstanceMethods
        def check_achievement
          WikiEditorAchievement.check_conditions_for(self)
        end
      end
    end
  end
end
