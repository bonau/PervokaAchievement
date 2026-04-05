# PervokaAchievement — Version Roadmap

## Overview

PervokaAchievement aims to be the most general-purpose achievement system for Redmine.
This roadmap covers v0.2 through v1.0, tracking milestones from compatibility restoration
to a fully configurable, notification-rich, and extensible achievement platform.

**Version strategy**: Semantic versioning (plugin-independent of Redmine version).
Redmine compatibility is documented per release in the changelog.

---

## v0.2 — Compatibility Release

**Goal**: First modern release. Establishes a stable, tested foundation.

- Redmine 5.1 / 6.1 compatibility
- Rails 6.x / 7.x compatibility
- Ruby 3.1 / 3.2 / 3.3 support
- Zeitwerk autoloading (removes deprecated `unloadable`)
- RSpec test suite (12 spec files, 65 tests)
- GitHub Actions CI/CD matrix (Ruby × Redmine combinations)
- Docker support
- 6 critical bug fixes (see project-001-revive retrospective)
- Plugin version reset to semantic versioning (0.2.0)

---

## v0.3 — Content & UX Expansion *(current develop)*

**Goal**: Broaden achievement variety and improve the display experience.

- Expanded built-in achievements from 4 to 11
  - Issue-based: CreateFirstIssue, ResolveFirstIssue, BugHunter, SpeedRunner
  - Comment-based: FirstComment (journal with notes)
  - Wiki-based: WikiEditor
  - Social: TeamPlayer (3+ project memberships)
- Achievement category system (issue, project, wiki, social, general)
- Categorized achievement list UI with section headers
- Inline-block card layout with improved timestamp display
- 3 new Redmine model patches: JournalPatch, WikiContentPatch, MemberPatch
- i18n expansion: added `ja.yml` (Japanese) and `zh-CN.yml` (Simplified Chinese)
- ~22 spec files, ~105 tests

> **Design decision**: Progress tracking and countable achievements (N > 1) deferred
> to v0.5. All v0.3 achievements are binary (one-time trigger). Time-based achievements
> (active on N consecutive days) also deferred to v0.5.

---

## v0.4 — Admin-Configurable Achievements *(Client-based)*

**Goal**: Redmine administrators can control achievements from the admin UI without
touching code.

- Admin panel at `/admin/achievements`
  - List all code-defined achievements
  - Enable / disable individual achievements
  - Override title, description, and quote per achievement (stored in DB, takes
    precedence over locale defaults)
- New `achievement_settings` table (or Redmine plugin settings mechanism)
- UI styled to match Redmine admin interface

> **Design note**: Achievement *conditions* remain code-defined in this version.
> Dynamic condition configuration via UI is scoped to v1.0+.

---

## v0.5 — Progress & Tier System

**Goal**: Support cumulative achievements and add depth through tiered rewards.

- Progress tracking (`achievement_progresses` table: `user_id`, `achievement_type`,
  `current_count`)
- Achievement tier support (Bronze / Silver / Gold, or custom levels)
- Progress bar displayed in the achievement list view
- Backfill mechanism for existing users' historical data

---

## v0.6 — Social & Discovery *(completed)*

**Goal**: Give the achievement system a sense of community.

- Achievement points system (10–25 pts per achievement based on difficulty)
  - Admin-configurable custom point values per achievement
  - Total score displayed on achievements page
- Shareable personal achievement page (opt-in public profile)
  - `AchievementUserSetting` model with `public_profile` toggle
  - Route: `GET /achievements/:id` for viewing other users' achievements
  - Admins can view any profile regardless of visibility settings
- Simple leaderboard view (`GET /achievements/leaderboard`)
  - Ranks users by total achievement score
  - Links to public profiles; current user highlighted
- Achievement tags system (milestone, exploratory, fun, skill, teamwork)
  - Color-coded tag badges on achievement cards
  - Tags visible in admin settings table
- 2 new migrations (004, 005), ~30 new specs
- i18n: all new strings in en, zh-TW, zh-CN, ja

> **Decision**: Leaderboard is accessible to any user with `:view_achievements`
> permission. Individual profile visibility is controlled by users via opt-in.

---

## v0.7 — Tiers, Progress & Notifications *(completed)*

**Goal**: Add depth through tiered rewards, progress tracking, and in-app notifications.

- Achievement tier system (Bronze / Silver / Gold)
  - Tier badges displayed on achievement cards and admin panel
  - Each achievement defines its tier based on difficulty
- Achievement progress tracking system
  - `achievement_progresses` table for multi-stage achievement support
  - `Achievement.target_count` and `Achievement.increment_progress_for` API
  - Progress bars displayed on unlockable achievements
- In-app toast notifications on achievement unlock
  - `notified_at` column on achievements table
  - Slide-in toast popup via view hook, auto-dismiss after 6 seconds
- 10 new achievements (total: 21)
  - Night Owl, Early Bird, Long Haul, Priority Expert, Detailed Reporter,
    Paperwork, Time Keeper, Self Starter, Weekend Warrior, Multi-tracker
- New `TimeEntryPatch` for time tracking hook
- Docker setup fixed (use official Redmine entrypoint)
- 2 new migrations (006, 007), ~50 new specs
- i18n: all new strings in en, zh-TW, zh-CN, ja

---

## v0.8 — Developer API & Extension Points *(completed)*

**Goal**: Allow other Redmine plugins to integrate cleanly with the achievement system.

- Public plugin API: `PervokaAchievement::Api.register_achievement(...)`
  - External plugins can register achievements without subclassing
  - `.award(:key, user)` and `.increment_progress(:key, user)` helpers
  - `.registered?` / `.registered_keys` for querying
- REST API endpoints (JSON, with `accept_api_auth`):
  - `GET /achievements.json` — current user's achievements
  - `GET /achievements/:id.json` — specific user's achievements
  - `GET /achievements/leaderboard.json` — ranked leaderboard
- Event hook interface: `PervokaAchievement::Api.on(:achievement_unlocked)`
  - Fired after any achievement is awarded (including external)
  - Error-isolated handlers (exceptions logged, not propagated)
- Versioned API documentation (`docs/API.md`)
- ~20 new specs for API and REST endpoints

---

## v0.9 — Stabilization & Polish

**Goal**: Final preparation for the v1.0 release.

- Performance audit: N+1 query fixes, missing DB index review
- Test coverage target: > 90%
- Baseline accessibility (a11y) improvements
- Complete user and developer documentation
- Compatibility matrix update for latest Redmine versions
- Deprecation cleanup

---

## v1.0 — General Achievement System (Stable Release)

**Goal**: Stable, complete, and extensible Redmine achievement system.

- All features from v0.2–v0.9 integrated
- Stable public API (SemVer guarantees)
- Full documentation: installation, extension, administration
- Performance and security review passed

---

## Post v1.0 Direction

After v1.0, the focus shifts toward making achievement *conditions* themselves
configurable without code changes:

- **Event sourcing architecture**: Abstract trigger conditions from code into a
  configurable event pipeline, enabling admins to define complete achievement
  conditions through the UI
- **Pluggable condition engine (rule engine)**: Composable condition building
  (e.g., "issues closed by user > 10 AND project = X")

This work will be planned incrementally starting in v1.x.
