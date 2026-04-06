PervokaAchievement
==================

[![CI](https://github.com/bonau/PervokaAchievement/workflows/CI/badge.svg)](https://github.com/bonau/PervokaAchievement/actions/workflows/ci.yml)
[![CodeQL](https://github.com/bonau/PervokaAchievement/workflows/CodeQL%20Analysis/badge.svg)](https://github.com/bonau/PervokaAchievement/actions/workflows/codeql.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

An extensible achievement system for Redmine. Users earn achievements for completing specific actions and receive notifications when they unlock new ones.

## Features

- **21 built-in achievements** across 5 categories (Issues, Projects, Wiki, Social, General)
- **Achievement tiers** (Bronze, Silver, Gold) based on difficulty
- **Progress tracking** for multi-stage achievements with progress bars
- **Points & leaderboard** with admin-configurable custom point values
- **Admin panel** to enable/disable achievements and customize text
- **In-app toast notifications** when achievements are unlocked
- **Email notifications** on achievement unlock
- **REST API** (JSON) for achievements, profiles, and leaderboard
- **Plugin API** for other Redmine plugins to register and award achievements
- **Event hooks** for reacting to achievement unlocks
- **User profile integration** via Redmine view hooks
- **Public achievement profiles** (opt-in per user)
- **i18n** support (English, Traditional Chinese, Simplified Chinese, Japanese)
- **Docker** support for easy deployment
- **300+ RSpec tests** with CI/CD via GitHub Actions

## Compatibility

| Redmine | Rails | Ruby |
|---------|-------|------|
| 5.1     | 6.x   | 3.1, 3.2 |
| 6.1     | 7.2   | 3.2, 3.3, 3.4 |

## Installation

Copy the plugin to your Redmine plugins directory:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/bonau/PervokaAchievement.git pervoka_achievement
```

Run the plugin migrations:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

Restart Redmine and you're done.

## Docker

```bash
docker-compose up -d
```

Visit `http://localhost:3000` (default credentials: admin / admin).

## Creating a New Achievement

Create a model in `app/models/`:

```ruby
# app/models/first_love_achievement.rb
class FirstLoveAchievement < Achievement
  def self.category = :issue
  def self.points = 10
  def self.tier = :bronze
  def self.tags = [:milestone]

  def self.check_conditions_for(user)
    return unless user.is_a?(User)
    super(user) { |u| Issue.where(assigned_to_id: [u.id] + u.group_ids).exists? }
  end
end
```

Add a patch to trigger it:

```ruby
# lib/pervoka_achievement/patches/issue_patch.rb
module PervokaAchievement
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      prepended do
        after_save :check_achievement
      end

      def check_achievement
        return unless saved_change_to_assigned_to_id?
        FirstLoveAchievement.check_conditions_for(assigned_to)
      end
    end
  end
end
```

Register the patch in `init.rb`:

```ruby
Issue.prepend PervokaAchievement::Patches::IssuePatch unless Issue < PervokaAchievement::Patches::IssuePatch
```

Add locale strings in `config/locales/en.yml`:

```yaml
en:
  achievement:
    first_love_achievement:
      title: First Love
      description: Assigned to at least one issue
      quote: First time's always painful.
```

## Plugin API

Other Redmine plugins can integrate with the achievement system:

```ruby
# Register an achievement
PervokaAchievement::Api.register_achievement :first_merge_request,
  category: :social, tier: :silver, points: 15

# Award it
PervokaAchievement::Api.award(:first_merge_request, user)

# Subscribe to events
PervokaAchievement::Api.on(:achievement_unlocked) do |payload|
  Rails.logger.info "#{payload[:user].login} unlocked #{payload[:achievement_class].name}"
end
```

See [docs/API.md](docs/API.md) for full API documentation.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the full roadmap from v0.2 to v1.0+.

## License

MIT
