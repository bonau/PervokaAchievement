Redmine::Plugin.register :pervoka_achievement do
  name 'Pervoka Achievement plugin'
  author 'munouzin'
  description 'An extensible achievement system for redmine, a fantastic project management web application.'
  version '0.4.0'
  url 'https://github.com/bonau/PervokaAchievement'
  author_url 'https://github.com/bonau'

  project_module :pervoka_achievement do
    permission :view_achievements, { achievements: [:index] }, public: true, read: true
  end

  menu :account_menu, :achievements, {controller: 'achievements', action: 'index'},
    caption: :"achievement.list_caption", first: true,
    if: Proc.new { User.current.allowed_to?(:view_achievements, nil, global: true) }
  menu :admin_menu, :achievements, {controller: 'admin_achievements', action: 'index'}, caption: :label_achievement_admin
end

Rails.configuration.to_prepare do
  User.prepend PervokaAchievement::Patches::UserPatch unless User < PervokaAchievement::Patches::UserPatch
  Issue.prepend PervokaAchievement::Patches::IssuePatch unless Issue < PervokaAchievement::Patches::IssuePatch
  Mailer.prepend PervokaAchievement::Patches::MailerPatch unless Mailer < PervokaAchievement::Patches::MailerPatch
  Project.prepend PervokaAchievement::Patches::ProjectPatch unless Project < PervokaAchievement::Patches::ProjectPatch
  Attachment.prepend PervokaAchievement::Patches::AttachmentPatch unless Attachment < PervokaAchievement::Patches::AttachmentPatch
  Journal.prepend PervokaAchievement::Patches::JournalPatch unless Journal < PervokaAchievement::Patches::JournalPatch
  WikiContent.prepend PervokaAchievement::Patches::WikiContentPatch unless WikiContent < PervokaAchievement::Patches::WikiContentPatch
  Member.prepend PervokaAchievement::Patches::MemberPatch unless Member < PervokaAchievement::Patches::MemberPatch
end
