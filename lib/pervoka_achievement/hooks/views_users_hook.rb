module PervokaAchievement
  module Hooks
    class ViewsUsersHook < Redmine::Hook::ViewListener
      render_on :view_account_left_bottom, partial: 'hooks/user_achievements'

      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('main', plugin: 'pervoka_achievement')
      end
    end
  end
end
