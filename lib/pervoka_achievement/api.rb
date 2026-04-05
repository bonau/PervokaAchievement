module PervokaAchievement
  # Public API for external plugins to integrate with the achievement system.
  #
  # == Registering achievements from another plugin
  #
  #   PervokaAchievement::Api.register_achievement :first_merge_request,
  #     category: :social,
  #     tier:     :bronze,
  #     points:   15,
  #     tags:     [:milestone],
  #     target_count: nil  # nil = single-stage, integer = progress-based
  #
  # Then award it when appropriate:
  #
  #   PervokaAchievement::Api.award(:first_merge_request, user)
  #
  # Or with progress-based achievements:
  #
  #   PervokaAchievement::Api.increment_progress(:code_reviewer, user)
  #
  # == Event hooks
  #
  #   PervokaAchievement::Api.on(:achievement_unlocked) do |payload|
  #     # payload[:user], payload[:achievement], payload[:achievement_class]
  #   end
  #
  module Api
    class << self
      # Registry of externally-defined achievements.
      # Maps Symbol key -> DynamicAchievement subclass.
      def external_achievements
        @external_achievements ||= {}
      end

      # Event subscribers. Maps event_name -> Array of Proc.
      def event_subscribers
        @event_subscribers ||= Hash.new { |h, k| h[k] = [] }
      end

      # Register a new achievement from an external plugin.
      #
      # @param key [Symbol] unique identifier (e.g. :first_merge_request)
      # @param options [Hash] achievement attributes
      # @option options [Symbol] :category (:general) one of Achievement::CATEGORIES
      # @option options [Symbol] :tier (:bronze) one of Achievement::TIERS
      # @option options [Integer] :points (10)
      # @option options [Array<Symbol>] :tags ([])
      # @option options [Integer, nil] :target_count (nil) for progress-based achievements
      # @return [Class] the generated achievement class
      def register_achievement(key, **options)
        key = key.to_sym
        raise ArgumentError, "Achievement :#{key} is already registered" if external_achievements.key?(key)

        class_name = key.to_s.camelize + 'Achievement'
        raise ArgumentError, "Class #{class_name} already exists" if Object.const_defined?(class_name)

        klass = Class.new(Achievement) do
          define_singleton_method(:category)     { options.fetch(:category, :general) }
          define_singleton_method(:tier)          { options.fetch(:tier, :bronze) }
          define_singleton_method(:points)        { options.fetch(:points, 10) }
          define_singleton_method(:tags)          { options.fetch(:tags, []) }
          define_singleton_method(:target_count)  { options.fetch(:target_count, nil) }
          define_singleton_method(:external?)     { true }
        end

        Object.const_set(class_name, klass)
        external_achievements[key] = klass
        klass
      end

      # Award an externally-registered achievement to a user.
      #
      # @param key [Symbol] achievement key (as passed to register_achievement)
      # @param user [User] the user to award
      # @return [Achievement, nil] the created record, or nil if already awarded / disabled
      def award(key, user)
        klass = resolve(key)
        return unless AchievementSetting.enabled?(klass)
        return if user.awarded?(klass)

        user.award(klass)
      end

      # Increment progress toward a progress-based externally-registered achievement.
      #
      # @param key [Symbol] achievement key
      # @param user [User] the user
      # @param increment [Integer] amount to increment (default 1)
      def increment_progress(key, user, increment: 1)
        klass = resolve(key)
        klass.increment_progress_for(user, increment: increment)
      end

      # Subscribe to an achievement system event.
      #
      # Supported events:
      #   :achievement_unlocked — fired after any achievement is awarded
      #     payload: { user:, achievement:, achievement_class: }
      #
      # @param event_name [Symbol]
      # @yield [Hash] event payload
      def on(event_name, &block)
        event_subscribers[event_name.to_sym] << block
      end

      # Fire an event to all subscribers. Called internally by the achievement system.
      #
      # @param event_name [Symbol]
      # @param payload [Hash]
      def fire_event(event_name, payload = {})
        event_subscribers[event_name.to_sym].each do |handler|
          handler.call(payload)
        rescue => e
          Rails.logger.error "[PervokaAchievement] Event handler error for #{event_name}: #{e.message}"
        end
      end

      # Check if an achievement key is registered.
      def registered?(key)
        external_achievements.key?(key.to_sym)
      end

      # List all registered external achievement keys.
      def registered_keys
        external_achievements.keys
      end

      # Reset the API state (primarily for testing).
      def reset!
        external_achievements.each_value do |klass|
          class_name = klass.name
          Achievement.registered_achievements.delete(klass)
          Object.send(:remove_const, class_name) if Object.const_defined?(class_name)
        end
        @external_achievements = {}
        @event_subscribers = Hash.new { |h, k| h[k] = [] }
      end

      private

      def resolve(key)
        klass = external_achievements[key.to_sym]
        raise ArgumentError, "Unknown external achievement :#{key}" unless klass

        klass
      end
    end
  end
end
