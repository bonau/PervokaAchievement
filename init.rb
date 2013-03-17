require_dependency 'user'
require_dependency 'issue'
require_dependency 'issue_observer'
require 'pervoka_achievement/user_patch'
require 'pervoka_achievement/issue_observer_patch'
require 'pervoka_achievement/mailer_patch'

Redmine::Plugin.register :pervoka_achievement do
  name 'Pervoka Achievement plugin'
  author 'munouzin'
  description 'An configurable achievement system for redmine, a fantastic project management web application.'
  version '0.0.1'
  url 'https://github.com/bonau/PervokaAchievement'
  author_url 'https://github.com/bonau'

  menu :account_menu, :achievements, {controller: 'achievements', action: 'index'}, caption: :"achievement.list_caption", first: true
end

Rails.configuration.to_prepare do
  User.send(:include, PervokaAchievement::Patches::UserPatch) unless User.included_modules.include?(PervokaAchievement::Patches::UserPatch)
  IssueObserver.send(:include, PervokaAchievement::Patches::IssueObserverPatch) unless IssueObserver.included_modules.include?(PervokaAchievement::Patches::IssueObserverPatch)
  Mailer.send(:include, PervokaAchievement::Patches::MailerPatch) unless Mailer.included_modules.include?(PervokaAchievement::Patches::MailerPatch)
end

RedmineApp::Application.configure do
  config.active_record.observers += [:issue_observer]
end
