# PervokaAchievement API Documentation

## Stability Guarantee

Starting with **v1.0**, this API follows [Semantic Versioning](https://semver.org/):

- **Public API surface**: All REST endpoints and the `PervokaAchievement::Api` module documented below.
- **Patch releases** (1.0.x): Bug fixes only. No API changes.
- **Minor releases** (1.x.0): New endpoints or options may be added. Existing endpoints and method signatures remain backwards-compatible.
- **Major releases** (x.0.0): Breaking changes to endpoints or method signatures.

**What is NOT part of the public API** (may change without notice):
- Internal model methods and associations not documented here
- View partials and HTML structure
- CSS class names and DOM structure
- Database schema (use the documented API, not direct DB queries)

---

## REST API

All REST endpoints require Redmine API authentication (API key or HTTP Basic auth)
and `rest_api_enabled` to be turned on in Redmine administration settings.

Pass the API key as `key` query parameter or `X-Redmine-API-Key` header.

### GET /achievements.json

Returns the current user's achievement list (unlocked and locked).

**Response:**

```json
{
  "user": { "id": 1, "login": "admin", "name": "Admin User" },
  "total_score": 45,
  "unlocked": [
    {
      "id": 1,
      "type": "FirstLoveAchievement",
      "name": "first_love_achievement",
      "category": "issue",
      "tier": "bronze",
      "points": 10,
      "tags": [],
      "target_count": null,
      "unlocked_at": "2026-04-01T12:00:00Z"
    }
  ],
  "locked": [
    {
      "type": "SpeedRunnerAchievement",
      "name": "speed_runner_achievement",
      "category": "issue",
      "tier": "gold",
      "points": 25,
      "tags": ["fun", "skill"],
      "target_count": null,
      "progress": null
    }
  ]
}
```

### GET /achievements/:user_id.json

Returns a specific user's achievements. Respects profile visibility settings
(public profile opt-in, or admin access).

### GET /achievements/leaderboard.json

Returns the achievement leaderboard, ranked by total score.

**Response:**

```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user": { "id": 2, "login": "jsmith", "name": "John Smith" },
      "score": 75,
      "achievement_count": 5
    }
  ]
}
```

---

## Plugin API

The Plugin API allows other Redmine plugins to integrate with the achievement system
without modifying PervokaAchievement's source code.

### Registering an Achievement

```ruby
# In your plugin's init.rb:
PervokaAchievement::Api.register_achievement :first_merge_request,
  category:     :social,     # one of :issue, :project, :wiki, :social, :general
  tier:         :silver,     # one of :bronze, :silver, :gold
  points:       15,
  tags:         [:milestone],
  target_count: nil          # nil = single-stage, integer = progress-based
```

### Awarding an Achievement

```ruby
# Award a single-stage achievement:
PervokaAchievement::Api.award(:first_merge_request, user)

# Increment a progress-based achievement:
PervokaAchievement::Api.increment_progress(:code_reviewer, user)
```

### Querying Registered Achievements

```ruby
PervokaAchievement::Api.registered?(:first_merge_request)  # => true
PervokaAchievement::Api.registered_keys                     # => [:first_merge_request]
```

---

## Event Hooks

Subscribe to achievement system events:

```ruby
PervokaAchievement::Api.on(:achievement_unlocked) do |payload|
  # payload keys:
  #   :user              - the User who unlocked the achievement
  #   :achievement       - the Achievement record
  #   :achievement_class - the achievement class (e.g. FirstLoveAchievement)

  Rails.logger.info "#{payload[:user].login} unlocked #{payload[:achievement_class].name}"
end
```

**Supported events:**

| Event | Fired when | Payload keys |
|-------|-----------|-------------|
| `:achievement_unlocked` | Any achievement is awarded | `user`, `achievement`, `achievement_class` |

Event handlers that raise exceptions are caught and logged; they do not
prevent the achievement from being saved.

---

## Authentication & Security

### REST API Authentication

All REST endpoints require one of:

- **API key** as `key` query parameter: `GET /achievements.json?key=YOUR_API_KEY`
- **API key** as HTTP header: `X-Redmine-API-Key: YOUR_API_KEY`
- **HTTP Basic auth** with Redmine credentials

The REST API must be enabled in Redmine: **Administration > Settings > API > Enable REST web service**.

### Profile Visibility

The `GET /achievements/:user_id.json` endpoint respects user privacy settings:

- Returns `403 Forbidden` if the target user has not enabled their public profile
- Admins bypass this restriction and can view any user's achievements
- Users can always view their own achievements

### Permissions

All achievement endpoints (both HTML and JSON) require the `view_achievements` permission assigned to the user's role in at least one project.
