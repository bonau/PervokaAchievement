PervokaAchievement
==================

[![CI](https://github.com/bonau/PervokaAchievement/workflows/CI/badge.svg)](https://github.com/bonau/PervokaAchievement/actions/workflows/ci.yml)
[![CodeQL](https://github.com/bonau/PervokaAchievement/workflows/CodeQL%20Analysis/badge.svg)](https://github.com/bonau/PervokaAchievement/actions/workflows/codeql.yml)
[![Docker Build](https://github.com/bonau/PervokaAchievement/workflows/CI/badge.svg?event=push)](https://github.com/bonau/PervokaAchievement/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

An extensible achievement system for redmine, a fantastic project management web application.

Every single achievement should be written in code, which is part of this achievement system.

## ✨ Features

- 🏆 Extensible achievement framework with 11 built-in achievements
- 📂 Achievement category system (Issues, Projects, Wiki, Social)
- 📧 Email notifications when achievements are unlocked
- 🎨 Categorized achievement display page with inline card layout
- 🌐 i18n support (English, Traditional Chinese, Japanese, Simplified Chinese)
- 🐳 Docker support for easy deployment
- ✅ Comprehensive RSpec test suite (~105 tests)
- 🔄 CI/CD with GitHub Actions


Install
-------

Simply copy this project to your own redmine directory:

    git clone git://github.com/bonau/PervokaAchievement.git /tmp/pervoka_achievement
    cp -a /tmp/pervoka_achievement /path/to/redmine/plugins/pervoka_achievement

or use it as a submodule: (_optional_)

    git submodule add git://github.com/bonau/PervokaAchievement.git plugins/pervoka_achievement
    git add .gitmodule plugins/pervoka_achievement
    git commit -m 'add pervoka achievement plugin'
    git submodule init # optional

And migrate the database by using redmine rake task.

    rake redmine:plugins:migrate NAME=pervoka_achievement

That's all.

Implement A New Achievement
---------------------------

Notice: write your own code in plugins/pervoka\_achievement, not the redmine framework itself.

### Create a model

To implement an achievement model, simply create a file named app/models/*name_achievement.rb*
(For example, "app/models/first\_love\_achievement.rb"). And then make it inherited from Achievement
model.

Achievement model has an implicit method *check_conditions_for(user)* for preventing a user from
receiving the same award twice or above. We can reuse it and add some flavor. The example below
shows how we could customize our own strategy:

    # app/models/first_love_achievement.rb
    class FirstLoveAchievement < Achievement
      def self.check_conditions_for(user)
        super(user) { |user| Issue.where(:assigned_to_id => ([user.id] + user.group_ids)).size > 0 }
      end
    end

### Add a patch to trigger the achievement

Now we have to decide when to check if the "First Love" achievement is reached.

Create a patch that hooks into the relevant model's lifecycle using `after_save` callbacks:

    # lib/pervoka_achievement/patches/issue_patch.rb
    module PervokaAchievement
      module Patches
        module IssuePatch
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
              after_save :check_achievement
            end
          end

          module InstanceMethods
            def check_achievement
              return unless saved_change_to_assigned_to_id?

              FirstLoveAchievement.check_conditions_for(self.assigned_to)
            end
          end
        end
      end
    end

### Register the patch

To register the patch we've created, add the following code in *init.rb*:

    Rails.configuration.to_prepare do
      Issue.send(:include, PervokaAchievement::Patches::IssuePatch) unless Issue.included_modules.include?(PervokaAchievement::Patches::IssuePatch)
    end


### Modify locale file
    # config/locales/en.yml
    en:
      achievement:
        first_love_achievement:
          title: First Love
          description: Assigned to at least one issue
          quote: First time's always painful.

Roadmap
-------

See [docs/roadmap.md](docs/roadmap.md) for the full roadmap from v0.2 to v1.0+.

