# 遷移至 GitHub Actions CI/CD 過程記錄

> 本文記錄將 PervokaAchievement Redmine 外掛從無 CI 狀態，遷移至完整 GitHub Actions CI/CD 流水線的完整過程，包含所有遭遇的問題與解決方式。

---

## 目錄

1. [背景與目標](#背景與目標)
2. [初始環境設定](#初始環境設定)
3. [CI 流水線架構](#ci-流水線架構)
4. [遭遇的問題與解決過程](#遭遇的問題與解決過程)
5. [最終通過的 CI 狀態](#最終通過的-ci-狀態)
6. [學到的教訓](#學到的教訓)

---

## 背景與目標

**專案**：PervokaAchievement — 一個為 Redmine 新增成就系統的外掛。

**初始狀態**：
- 測試框架為 Minitest（舊版）
- 沒有任何 CI/CD 流水線
- 程式碼使用 Rails 2.x 風格語法（已過時）

**目標**：
- 將測試框架遷移至 RSpec
- 建立 GitHub Actions 自動化 CI/CD
- 支援 Ruby 3.1/3.2 × Redmine 5.0/5.1 的矩陣測試
- 最終讓所有 CI check 通過

---

## 初始環境設定

### 安裝 GitHub CLI

```bash
brew install gh
gh auth login
```

### 建立 Pull Request

```bash
gh pr create --title "..." --body-file PR_DESCRIPTION.md --base master
```

> **注意**：該專案的預設分支為 `master`（非 `main`），建立 PR 時需明確指定 `--base master`。

---

## CI 流水線架構

### 測試矩陣（`.github/workflows/ci.yml`）

| Ruby 版本 | Redmine 5.0 | Redmine 5.1 |
|-----------|-------------|-------------|
| 3.1       | ✅ 測試      | ✅ 測試      |
| 3.2       | ❌ 排除      | ✅ 測試      |

Ruby 3.2 與 Redmine 5.0 不相容（Gemfile 限制 `< 3.2.0`），因此在矩陣中排除。

### 工作流程清單

| 工作流程 | 說明 |
|---------|------|
| `ci.yml` | RSpec 測試、RuboCop、Syntax Check、Docker Build |
| `codeql.yml` | CodeQL 安全掃描 |
| `release.yml` | 自動化發佈管理 |
| `stale.yml` | 舊 Issue 自動管理 |

### CI 依賴安裝順序

```yaml
- name: Install dependencies
  run: |
    echo "gem 'rspec-rails', '~> 6.0', group: [:development, :test]" >> Gemfile.local
    echo "gem 'rspec_junit_formatter', group: [:test]" >> Gemfile.local
    echo "gem 'rails-controller-testing', group: [:test]" >> Gemfile.local
    bundle install --gemfile Gemfile --jobs 4 --retry 3
    bundle exec rake db:migrate RAILS_ENV=test
    bundle exec rake redmine:plugins:migrate RAILS_ENV=test
```

---

## 遭遇的問題與解決過程

以下依照發現順序逐一記錄所有 CI 失敗原因與修正方式。

---

### 問題 1：`bundle install --without ""` 導致 gems 未安裝

**錯誤訊息**：
```
Could not find gem 'rspec-rails' in any of the gem sources
```

**原因**：`Dockerfile` 中有 `bundle install --without ""`，空字串參數在某些 Bundler 版本下會被解讀為排除所有群組。

**修正**（`Dockerfile`）：
```diff
- bundle install --without ""
+ bundle install
```

---

### 問題 2：Zeitwerk 找不到常數

**錯誤訊息**：
```
Zeitwerk::NameError: expected file .../lib/pervoka_achievement/attachment_patch.rb
to define constant PervokaAchievement::AttachmentPatch, but didn't
```

**原因**：檔案放在 `lib/pervoka_achievement/attachment_patch.rb`，但模組定義是 `PervokaAchievement::Patches::AttachmentPatch`（多了 `Patches` 層），與 Zeitwerk 的路徑→常數對應規則不符。

**修正**：
1. 將所有 patch 檔移至 `lib/pervoka_achievement/patches/` 目錄
2. 更新 `init.rb` 的 glob 路徑從 `./lib/pervoka_achievement/*.rb` 改為 `./lib/pervoka_achievement/**/*.rb`

---

### 問題 3：Ruby 3.2 與 Redmine 5.0 不相容

**錯誤訊息**：
```
Your Ruby version is 3.2.10, but your Gemfile specified >= 2.5.0, < 3.2.0
```

**原因**：Redmine 5.0 的 Gemfile 明確限制 Ruby 版本上限為 3.2.0（不含）。

**修正**（`.github/workflows/ci.yml`）：
```yaml
strategy:
  matrix:
    ruby: ['3.1', '3.2']
    redmine: ['5.0', '5.1']
    exclude:
      - ruby: '3.2'
        redmine: '5.0'
```

---

### 問題 4：`docker-compose` 指令不存在

**錯誤訊息**：
```
docker-compose: command not found
```

**原因**：GitHub Actions 的 runner 環境只有 Docker CLI v2（`docker compose`），已不再提供舊版的獨立 `docker-compose` 執行檔。

**修正**（`.github/workflows/ci.yml`）：
```diff
- docker-compose --version
+ docker compose version
```

---

### 問題 5：資料庫遷移版本未指定

**錯誤訊息**：
```
StandardError: Directly inheriting from ActiveRecord::Migration is not supported.
Please specify the Rails release the migration was written for.
```

**原因**：遷移檔案使用舊式 `class CreateAchievements < ActiveRecord::Migration`，Rails 5+ 要求明確標注版本。

**修正**（所有 `db/migrate/*.rb`）：
```diff
- class CreateAchievements < ActiveRecord::Migration
+ class CreateAchievements < ActiveRecord::Migration[6.1]
```

---

### 問題 6：RSpec `fixture_paths=` 在 Rails 6.x 不存在

**錯誤訊息**：
```
NoMethodError: undefined method 'fixture_paths=' for RSpec::Rails::Configuration
```

**原因**：`fixture_paths=`（複數）是 Rails 7+ 新增的 API；Rails 6.x 只有 `fixture_path=`（單數）。

**修正**（`spec/spec_helper.rb`）：
```ruby
if config.respond_to?(:fixture_paths=)
  config.fixture_paths = ["#{REDMINE_TEST_DIR}/fixtures"]
else
  config.fixture_path = "#{REDMINE_TEST_DIR}/fixtures"
end
```

---

### 問題 7：手動 `require` 與 Zeitwerk 自動載入衝突

**錯誤訊息**：
```
NoMethodError: undefined method 'check_achievement' for Issue
NoMethodError: undefined method 'achievements' for User
```

**原因**：`init.rb` 手動 `require` 了 `app/models` 和 `lib` 下的檔案，這些路徑同時也在 Zeitwerk 的自動載入範圍內。兩者競爭導致常數被載入兩次、patch 未正確掛載。

**修正**（`init.rb`）：移除所有手動 `require`，完全依賴 Zeitwerk 自動載入。

```diff
- plugin_dir = File.dirname(__FILE__)
- ['./app/models/achievement.rb', './app/models/*.rb', './lib/pervoka_achievement/**/*.rb'].each do |path|
-   Dir[File.expand_path(path, plugin_dir)].each { |f| require f }
- end
-
  Redmine::Plugin.register :pervoka_achievement do
```

並在 `spec/spec_helper.rb` 明確套用 patch：

```ruby
Rails.application.eager_load!

[
  [User,       PervokaAchievement::Patches::UserPatch],
  [Issue,      PervokaAchievement::Patches::IssuePatch],
  [Mailer,     PervokaAchievement::Patches::MailerPatch],
  [Project,    PervokaAchievement::Patches::ProjectPatch],
  [Attachment, PervokaAchievement::Patches::AttachmentPatch],
].each do |klass, patch|
  klass.send(:include, patch) unless klass.included_modules.include?(patch)
end
```

---

### 問題 8：Rails 2.x 的過時 ActiveRecord 查詢語法

**錯誤訊息**：
```
NoMethodError: undefined method 'synchronize' for nil:NilClass
```

**原因**：`user_patch.rb` 使用了 Rails 2.x 的 `count(:conditions => { ... })` 語法，在 Rails 6+/7 中，`:conditions` 選項已被移除，導致內部狀態異常。

**修正**（`lib/pervoka_achievement/patches/user_patch.rb`）：
```diff
- achievements.count(:conditions => { :type => achievement }) > 0
+ achievements.where(type: achievement.to_s).exists?
```

---

### 問題 9：`Achievement.inherited` 未呼叫 `super`

**錯誤訊息**：
```
NoMethodError: undefined method 'synchronize' for #<Module:0x...>
```

**原因**：`Achievement.inherited(base)` 沒有呼叫 `super`，導致 `ActiveRecord::Base.inherited` 無法執行，子類別的 `@load_schema_monitor` 等 ActiveRecord 內部狀態未初始化。

**修正**（`app/models/achievement.rb`）：
```diff
  def self.inherited(base)
+   super
    Achievement.registered_achievements << base
  end
```

---

### 問題 10：Redmine Mailer 要求第一個參數必須是 User

**錯誤訊息**：
```
ArgumentError: First argument has to be a user, was #<FirstLoveAchievement ...>
```

**原因**：Redmine 的 `Mailer#process` 方法在呼叫所有 mailer 方法前，會驗證第一個參數必須是 `User` 物件。原本 `achievement_unlocked(achievement)` 的方法簽名不符合此規定。

**修正**：

`lib/pervoka_achievement/patches/mailer_patch.rb`：
```diff
- def achievement_unlocked(achievement)
-   user = achievement.user
+ def achievement_unlocked(user, achievement)
```

`app/models/achievement.rb`：
```diff
- Mailer.achievement_unlocked(self).deliver_now
+ Mailer.achievement_unlocked(user, self).deliver_later
```

`deliver_later` 相較於 `deliver_now` 的優點：將郵件投遞與 DB 交易解耦，避免 after_create callback 中因郵件模板問題導致整個交易失敗。

---

### 問題 11：`assigns` helper 已被移到獨立 gem

**錯誤訊息**：
```
NoMethodError: assigns has been extracted to a gem.
To continue using it, add 'gem rails-controller-testing' to your Gemfile.
```

**原因**：Rails 5+ 將 Controller spec 的 `assigns` helper 移至 `rails-controller-testing` gem，不再內建。

**修正**（`.github/workflows/ci.yml`）：
```bash
echo "gem 'rails-controller-testing', group: [:test]" >> Gemfile.local
```

---

### 問題 12：Issue fixture 驗證失敗（Priority、Tracker、Category）

**錯誤訊息**：
```
ActiveRecord::RecordInvalid: Validation failed: Priority cannot be blank
ActiveRecord::RecordInvalid: Validation failed: Tracker is not included in the list
ActiveRecord::RecordInvalid: Validation failed: Category is not included in the list
```

**原因**：
- Redmine 的 `IssuePriority` 資料存放在 `enumerations` 表格，對應 fixture 為 `:enumerations`（非 `:issue_priorities`）
- Tracker 驗證需要 `:projects_trackers` fixture 建立 project 與 tracker 的關聯
- Category 驗證需要 `:issue_categories` fixture

**修正**（各測試檔案的 `fixtures` 宣告）：
```ruby
fixtures :users, :projects, :issues, :trackers, :issue_statuses,
         :enumerations, :issue_categories, :projects_trackers,
         :roles, :members, :member_roles, :enabled_modules
```

另外，`Issue.create!` 需明確指定 priority：
```ruby
let(:priority) { IssuePriority.first }

Issue.create!(
  project_id: 1, tracker_id: 1, subject: 'Test Issue',
  author_id: 1, assigned_to_id: user.id, status_id: 1,
  priority: priority
)
```

---

### 問題 13：Controller 重新導向測試路徑不精確

**錯誤訊息**：
```
expected response to redirect to </login>
but was </login?back_url=%2Fachievements>
```

**原因**：Redmine 的 `require_login` 重新導向時會附帶 `?back_url=...` 查詢參數，直接用 `redirect_to(signin_path)` 比對會失敗。

**修正**（controller spec）：
```ruby
it 'redirects to login' do
  get :index
  expect(response).to have_http_status(:redirect)
  expect(response.location).to include('/login')
end
```

---

### 問題 14：`check_conditions_for` 的 block 測試邏輯錯誤

**錯誤訊息**：
```
expected `user.achievements.count` not to have changed, but did change from 0 to 1
```

**原因**：`FirstLoveAchievement` 覆寫了 `check_conditions_for(user)` 且方法簽名不接受 block。因此測試中傳入的 `{ false }` block 被 Ruby **靜默丟棄**，實際執行的是 `FirstLoveAchievement` 自己的 Issue 查詢邏輯。若資料庫中存在 Issue fixture（由其他測試檔案載入），就會意外觸發成就授予。

**根本問題**：這個測試的用意是驗證**基類 `Achievement` 的 block 機制**，但卻使用了覆寫該機制的子類別。

**修正**（`spec/models/achievement_spec.rb`）：
```diff
- FirstLoveAchievement.check_conditions_for(user) { false }
+ Achievement.check_conditions_for(user) { false }

- FirstLoveAchievement.check_conditions_for(user) { true }
+ Achievement.check_conditions_for(user) { true }
```

---

## 最終通過的 CI 狀態

所有 CI checks 均通過（2026-02-18）：

| Check | 狀態 |
|-------|------|
| RSpec Tests (Ruby 3.1 / Redmine 5.0) | ✅ pass |
| RSpec Tests (Ruby 3.1 / Redmine 5.1) | ✅ pass |
| RSpec Tests (Ruby 3.2 / Redmine 5.1) | ✅ pass |
| RuboCop | ✅ pass |
| Syntax Check | ✅ pass |
| Docker Build Test | ✅ pass |
| Analyze Code (ruby) / CodeQL | ✅ pass |

---

## 學到的教訓

### 關於 Zeitwerk 自動載入

- **不要混用** 手動 `require` 和 Zeitwerk 自動載入。對 `app/` 和 `lib/` 下的檔案，統一使用 Zeitwerk，只在非自動載入路徑的外部依賴才手動 `require`。
- 檔案路徑與模組命名空間**必須嚴格對應**。`lib/foo/bar/baz.rb` 必須定義 `Foo::Bar::Baz`。
- 在測試環境中呼叫 `Rails.application.eager_load!` 可以避免 Zeitwerk 懶載入與 RSpec mocking 衝突的問題。

### 關於 Rails 版本相容性

- 遷移舊專案時，**逐一審查每個 ActiveRecord 查詢**是否使用了 Rails 2.x/3.x 的過時語法（如 `:conditions => {}`）。
- `ActiveRecord::Migration` 子類別必須標注 Rails 版本，如 `Migration[6.1]`。
- `fixture_paths=`（複數）是 Rails 7+ 才有的 API；Rails 6.x 使用 `fixture_path=`（單數）。

### 關於 Redmine 外掛開發

- Redmine 的 `Mailer#process` 強制要求所有 mailer 方法**第一個參數必須是 `User` 物件**。
- `IssuePriority` 是 `Enumeration` 的子類別，使用 STI，fixture 名稱為 `:enumerations`，**不是** `:issue_priorities`。
- Redmine 的 `require_login` helper 重新導向時會帶 `?back_url=...`，測試時應用 `include('/login')` 而非精確路徑比對。

### 關於 RSpec 測試設計

- 測試**基類行為**時，應直接對基類呼叫方法，而非使用覆寫了該方法的子類別。
- fixture 資料庫在測試 suite 中**全域共享**（非每個 example 獨立）。當測試依賴「沒有特定資料」的狀態時，要留意其他測試檔案載入的 fixture 可能污染狀態。
- 在測試涉及 `after_create :deliver_mail` 的 model 時，應在測試中 stub Mailer，避免模板或語言設定問題導致測試失敗。

### 關於 CI 矩陣測試

- 使用 `exclude` 明確排除不相容的版本組合，比使用 `include` 逐一列舉相容組合更簡潔易維護。
- 在 `Gemfile.local` 追加 gem 是在不修改 Redmine 本體 `Gemfile` 的前提下，為測試環境新增依賴的標準做法。
- `docker-compose`（v1 獨立執行檔）在現代 CI 環境已被 `docker compose`（Docker CLI v2 子命令）取代。

---

*最後更新：2026-02-19*
