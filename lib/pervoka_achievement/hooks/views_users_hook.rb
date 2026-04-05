module PervokaAchievement
  module Hooks
    class ViewsUsersHook < Redmine::Hook::ViewListener
      render_on :view_account_left_bottom, partial: 'hooks/user_achievements'

      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('main', plugin: 'pervoka_achievement')
      end

      def view_layouts_base_body_bottom(context = {})
        return '' unless User.current.logged?

        unnotified = Achievement.where(user_id: User.current.id, notified_at: nil)
        return '' if unnotified.empty?

        ids = unnotified.map(&:id)
        titles = unnotified.map { |a| I18n.t(a.locale_prefix(:title)) }
        Achievement.where(id: ids).update_all(notified_at: Time.current)

        context[:controller].send(:render_to_string, {
          partial: 'hooks/achievement_toast',
          locals: { titles: titles }
        })
      end
    end
  end
end
