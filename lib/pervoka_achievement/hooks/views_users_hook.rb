module PervokaAchievement
  module Hooks
    class ViewsUsersHook < Redmine::Hook::ViewListener
      render_on :view_account_left_bottom, partial: 'hooks/user_achievements'
    end
  end
end
