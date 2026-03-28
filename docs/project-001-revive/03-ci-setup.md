# GitHub Actions CI/CD 建立過程記錄

## 建立階段（`70de5c2`）

首次建立 `.github/workflows/ci.yml`，包含：
- RSpec 測試矩陣（Ruby 3.1/3.2 × Redmine 5.0/5.1）
- RuboCop 靜態分析
- Ruby Syntax Check
- Docker Build 驗證
- 附帶：CodeQL、Release、Stale、Badge Generator 工作流程

---

## CI 失敗修補記錄

### 修補 1：`release.yml` secrets 條件錯誤（`724b61c`）

**症狀**：`if: secrets.GITHUB_TOKEN != ''` 語法在 GitHub Actions 不合法（secrets 不能在 `if` 中直接比較字串）。

**修法**：改為 `if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')`。

---

### 修補 2：`rspec_junit_formatter` gem 缺失（`b35b6e5`）

**症狀**：CI 執行時找不到 `rspec_junit_formatter`，因為只在 ci.yml 的 `--format` 參數中用到，卻未在 Gemfile.local 或 Dockerfile 中加入。

**修法**：
- `ci.yml`：`Gemfile.local` 加入 `gem 'rspec_junit_formatter'`
- `Dockerfile`：在 gem 安裝清單加入該 gem

---

### 修補 3：`docker-compose --version` 指令過時（`fcce37a`、`b6487bb`）

**症狀**：新版 Docker CLI 中 `docker-compose` 是獨立二進位，已不預設安裝；GitHub Actions runner 只有 `docker compose`（plugin）。

**修法**：改為 `docker compose version`。

---

### 修補 4：bundle install `--without` 空值問題（`fcce37a`）

**症狀**：Dockerfile 中 `bundle install --without ""` 傳入空字串導致 bundler 警告或錯誤。

**修法**：移除 `--without` 參數（或不傳入空值）。

---

### 修補 5：patch 檔案路徑不在 glob 範圍（`b6487bb`）

**症狀**：`lib/pervoka_achievement/*.rb` 不包含 `patches/` 子目錄，導致 CI 中 patches 未被 require。

**修法**：
1. 將 patch 檔案移至 `lib/pervoka_achievement/patches/` 子目錄（統一結構）
2. init.rb glob 改為 `lib/pervoka_achievement/**/*.rb`（後在 `977e483` 中整體刪除，改由 Zeitwerk autoload）

---

### 修補 6：init.rb 手動 require 與 Zeitwerk 衝突（`977e483`）

**症狀**：init.rb 的手動 `require` 與 Zeitwerk autoloader 重複載入，導致常數衝突或重複 include。

**修法**：完整移除 init.rb 中的手動 require 迴圈，全部交由 Zeitwerk 處理。

---

### 修補 7：Rails migration 版本未指定（`40eb906`）

**症狀**：Rails 6.1 要求 migration 繼承 `ActiveRecord::Migration[X.Y]`，舊寫法 `< ActiveRecord::Migration` 產生 deprecation warning 甚至失敗。

**修法**：
```ruby
# 修前
class CreateAchievements < ActiveRecord::Migration
# 修後
class CreateAchievements < ActiveRecord::Migration[6.1]
```

---

### 修補 8：`rails-controller-testing` gem 缺失（`3d90abf`）

**症狀**：`AchievementsController` spec 使用 `assigns()` helper，Rails 5+ 需要 `rails-controller-testing` gem 才有此 helper。

**修法**：在 `Gemfile.local` 加入 `gem 'rails-controller-testing'`。

---

## 矩陣設計決策

初版使用 `include` 指定「必測」組合：
```yaml
include:
  - ruby: '3.1'
    redmine: '5.0'
  - ruby: '3.2'
    redmine: '5.1'
```

這其實只測 2 組，其餘的 `matrix` 宣告是多餘的。
後改為 `exclude` 排除不相容的 Ruby 3.2 + Redmine 5.0，讓 3 組合都測到：

```yaml
exclude:
  - ruby: '3.2'
    redmine: '5.0'
```

這樣 Ruby 3.1 × Redmine 5.0、Ruby 3.1 × Redmine 5.1、Ruby 3.2 × Redmine 5.1 三組都會執行。
