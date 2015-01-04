module PervokaAchievement
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method :old_close, :close
          def close
            old_close
            CloseProjectAchievement.check_conditions_for(self)
          end
        end
      end

      module ClassMethods
      end
      module InstanceMethods
      end
    end
  end
end
