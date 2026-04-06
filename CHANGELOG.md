# Changelog

All notable changes to PervokaAchievement are documented in this file.

## [0.8.0] - 2026-04-01

### Added
- Public plugin API (`PervokaAchievement::Api.register_achievement`, `.award`, `.increment_progress`)
- Event hook interface (`PervokaAchievement::Api.on(:achievement_unlocked)`)
- REST API endpoints: `GET /achievements.json`, `GET /achievements/:id.json`, `GET /achievements/leaderboard.json`
- API documentation (`docs/API.md`)
- ~20 new specs for API and REST endpoints

## [0.7.0] - 2026-03-15

### Added
- Achievement tier system (Bronze, Silver, Gold)
- Achievement progress tracking with `achievement_progresses` table
- In-app toast notifications on achievement unlock
- 10 new achievements: Night Owl, Early Bird, Long Haul, Priority Expert, Detailed Reporter, Paperwork, Time Keeper, Self Starter, Weekend Warrior, Multi-tracker
- `TimeEntryPatch` for time tracking hooks
- 2 new migrations (006, 007), ~50 new specs

### Fixed
- Docker setup (use official Redmine entrypoint)

## [0.6.0] - 2026-03-01

### Added
- Achievement points system (10-25 pts per achievement)
- Admin-configurable custom point values
- Shareable personal achievement pages (opt-in public profiles)
- Simple leaderboard view ranked by total score
- Achievement tags system (milestone, exploratory, fun, skill, teamwork)
- 2 new migrations (004, 005), ~30 new specs

## [0.5.0] - 2026-02-15

### Added
- Achievement progress tracking (`achievement_progresses` table)
- Achievement tier support (Bronze / Silver / Gold)
- Progress bars in achievement list view

## [0.4.0] - 2026-02-01

### Added
- Admin panel at `/admin/achievements`
- Enable/disable individual achievements
- Override title, description, and quote per achievement
- `achievement_settings` table

## [0.3.0] - 2026-01-15

### Added
- 7 new achievements: CreateFirstIssue, ResolveFirstIssue, BugHunter, SpeedRunner, FirstComment, WikiEditor, TeamPlayer
- Achievement category system (issue, project, wiki, social, general)
- Categorized achievement list UI
- 3 new patches: JournalPatch, WikiContentPatch, MemberPatch
- Japanese and Simplified Chinese translations
- ~105 total specs

## [0.2.0] - 2026-01-01

### Changed
- Redmine 5.1 / 6.1 compatibility
- Rails 6.x / 7.x compatibility
- Ruby 3.1 / 3.2 / 3.3 support
- Zeitwerk autoloading
- Migrated from `include` to `prepend` patch pattern
- Migrated test suite to RSpec (65 specs)

### Fixed
- 6 critical bugs (typos, deprecated APIs, broken patches)

### Added
- GitHub Actions CI/CD
- Docker support
