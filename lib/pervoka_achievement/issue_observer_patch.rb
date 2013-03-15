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
        def after_update(record)
          FirstLoveAchievement.check_conditions_for(User.current)
        end
      end
    end
  end
end
