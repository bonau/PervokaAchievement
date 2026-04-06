# Administration Guide

This guide covers how to configure and manage PervokaAchievement as a Redmine administrator.

## Permissions

PervokaAchievement adds one permission that can be assigned to roles:

- **View achievements** (`view_achievements`) — allows users to see the achievement list, their profile, the leaderboard, and the profile hook on user pages.

Go to **Administration > Roles and permissions** and check **View achievements** for each role that should have access.

## Admin Panel

Navigate to **Administration > Achievements** (`/admin/achievements`) to manage all registered achievements.

### Enable / Disable Achievements

Each achievement has a checkbox in the **Enabled** column. Uncheck it to prevent the achievement from being awarded. Disabled achievements are hidden from the user-facing achievement list.

### Customize Points

Enter a number in the **Points** column to override the default point value. Leave it blank to use the code-defined default (shown as placeholder text).

### Customize Text

You can override the **Title**, **Description**, and **Quote** for any achievement. These overrides take precedence over the locale defaults. Leave fields blank to use the default i18n text.

HTML tags are automatically stripped from custom text for security.

### Saving Changes

Click **Save** at the bottom of the page. All changes are applied at once.

## Achievement Categories

Achievements are organized into five categories:

| Category | Description |
|----------|-------------|
| Issue    | Creating, resolving, and working with issues |
| Project  | Closing or reopening projects |
| Wiki     | Editing wiki pages |
| Social   | Comments, attachments, team membership |
| General  | Time tracking, file uploads, other actions |

## Achievement Tiers

Each achievement has a tier reflecting its difficulty:

| Tier   | Typical criteria |
|--------|-----------------|
| Bronze | Simple one-time actions (e.g., create first issue) |
| Silver | Actions requiring effort or time (e.g., 10+ bug reports) |
| Gold   | Challenging or rare accomplishments (e.g., close an issue within 24h) |

## Achievement Tags

Tags provide a secondary classification:

- **milestone** — first-time accomplishments
- **exploratory** — trying new features
- **fun** — lighthearted achievements
- **skill** — demonstrating expertise
- **teamwork** — collaborative actions

## Leaderboard

The leaderboard at `/achievements/leaderboard` ranks all active users by total achievement score. It is visible to anyone with the `view_achievements` permission.

## User Profiles

Users can opt in to a public achievement profile at `/achievements/:user_id`. The toggle is on their own achievements page. Admins can view any user's profile regardless of the visibility setting.

## Notifications

When a user unlocks an achievement:

1. **Email** — a notification email is sent immediately.
2. **Toast** — an in-app popup appears on the next page load (auto-dismisses after 6 seconds).

Both notifications are automatic and cannot be individually disabled. To prevent notifications for a specific achievement, disable the achievement in the admin panel.

## REST API

When Redmine's REST API is enabled (**Administration > Settings > API > Enable REST web service**), the following JSON endpoints are available:

| Endpoint | Description |
|----------|-------------|
| `GET /achievements.json` | Current user's achievements |
| `GET /achievements/:id.json` | Specific user's achievements (respects visibility) |
| `GET /achievements/leaderboard.json` | Ranked leaderboard |

See [API.md](API.md) for full details.

## Plugin API

Other Redmine plugins can register achievements and subscribe to events. See [API.md](API.md) for the developer API reference.
