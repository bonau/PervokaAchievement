module PervokaAchievement
  module Patches
    module IssueObserverPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          observe :issue
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def after_save(record)
          FirstLoveAchievement.check_conditions_for(record.assigned_to)
        end
      end
    end
  end
end
