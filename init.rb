Redmine::Plugin.register :pervoka_achievement do
  name 'Pervoka Achievement plugin'
  author 'munouzin'
  description 'An extensible achievement system for redmine, a fantastic project management web application.'
  version '0.2.1'
  url 'https://github.com/bonau/PervokaAchievement'
  author_url 'https://github.com/bonau'

  menu :account_menu, :achievements, {controller: 'achievements', action: 'index'}, caption: :"achievement.list_caption", first: true
end

Rails.configuration.to_prepare do
  User.send(:include, PervokaAchievement::Patches::UserPatch) unless User.included_modules.include?(PervokaAchievement::Patches::UserPatch)
  Issue.send(:include, PervokaAchievement::Patches::IssuePatch) unless Issue.included_modules.include?(PervokaAchievement::Patches::IssuePatch)
  Mailer.send(:include, PervokaAchievement::Patches::MailerPatch) unless Mailer.included_modules.include?(PervokaAchievement::Patches::MailerPatch)
  Project.send(:include, PervokaAchievement::Patches::ProjectPatch) unless Project.included_modules.include?(PervokaAchievement::Patches::ProjectPatch)
  Attachment.send(:include, PervokaAchievement::Patches::AttachmentPatch) unless Attachment.included_modules.include?(PervokaAchievement::Patches::AttachmentPatch)
end
