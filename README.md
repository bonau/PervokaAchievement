PervokaAchievement
==================

An configurable achievement system for redmine, a fantastic project management web application.

Every single achievement should be written in code, which is part of this achievement system.


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

### Add an observer

Now we have to decide when to check if the "First Love" achievement is reached.

ActiveRecord::Observer provides an effcient way to run some codes without monitor the whole database.
Normally the observer codes are in app/models, but in this case, redmine has already implemented
IssueObserver in app/models/issue\_observer.rb (redmine directory). All we have to do is to write a
patch in lib/ (we will register it later).

    # lib/pervoka_achievement/issue_observer_patch.rb
    module PervokaAchievement
      module Patches
        module IssueObserverPatch
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
              observe :issue
            end
          end

          module InstanceMethods
            def after_save(record)
              FirstLoveAchievement.check_conditions_for(record.assigned_to)
            end
          end
        end
      end
    end

### Register all patches

To register the patch we've created, add the following codes in *init.rb*

    require 'pervoka_achievement/issue_observer_patch'
    Rails.configuration.to_prepare do
      IssueObserver.send(:include, PervokaAchievement::Patches::IssueObserverPatch) unless IssueObserver.included_modules.include?(PervokaAchievement::Patches::IssueObserverPatch)
    end

Futhermore, don't forget to register the observers in *init.rb* if you have any written in app/models
but has not been registered in redmine.

    RedmineApp::Application.configure do
      config.active_record.observers += [:the_new_observer]
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

### v0.1
Basic achievement system implemented.

### v0.4 (not implemented yet)
Client-based achievement will be supported.

### v0.7 (not implemented yet)
One or more notification system will be involved.

