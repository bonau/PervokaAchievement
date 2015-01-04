plugin_dir =  File.dirname(__FILE__)
['./app/models/achievement.rb', './app/models/*.rb', './lib/pervoka_achievement/*.rb'].each do |path|
  Dir[File.expand_path(path, plugin_dir)].each { |f| require f }
end

Redmine::Plugin.register :pervoka_achievement do
  name 'Pervoka Achievement plugin'
  author 'munouzin'
  description 'An configurable achievement system for redmine, a fantastic project management web application.'
  version '0.0.2'
  url 'https://github.com/bonau/PervokaAchievement'
  author_url 'https://github.com/bonau'

  menu :account_menu, :achievements, {controller: 'achievements', action: 'index'}, caption: :"achievement.list_caption", first: true
end

Rails.configuration.to_prepare do
  User.send(:include, PervokaAchievement::Patches::UserPatch) unless User.included_modules.include?(PervokaAchievement::Patches::UserPatch)
  Issue.send(:include, PervokaAchievement::Patches::IssuePatch) unless Issue.included_modules.include?(PervokaAchievement::Patches::IssuePatch)
  Mailer.send(:include, PervokaAchievement::Patches::MailerPatch) unless Mailer.included_modules.include?(PervokaAchievement::Patches::MailerPatch)
  Project.send(:include, PervokaAchievement::Patches::ProjectPatch) unless Project.included_modules.include?(PervokaAchievement::Patches::ProjectPatch)
end
