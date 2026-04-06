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
        settings_cache = AchievementSetting.all.index_by(&:achievement_type)
        Achievement.where(user_id: id).to_a.sum { |a| a.class.effective_points(settings_cache) }
      end
    end
  end
end
