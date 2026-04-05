module PervokaAchievement
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      prepended do
        has_many :achievements
      end

      def awarded?(achievement)
        achievements.where(type: achievement.to_s).exists?
      end

      def award(achievement)
        achievement.create(user: self)
      end

      def achievement_score
        achievements.sum { |a| a.class.effective_points }
      end
    end
  end
end
