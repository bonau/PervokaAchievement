# PervokaAchievement 改善計畫

## 一、現狀分析

### 1.1 專案概述

PervokaAchievement 是一個 Redmine 成就系統插件，讓使用者在完成特定動作時獲得成就並收到郵件通知。目前版本為 `0.0.2`（develop 分支），基於 **Rails 3.x / Redmine 2.x** 時代開發。

### 1.2 目前功能（develop 分支）

| 功能 | 狀態 | 說明 |
|------|------|------|
| 成就基底模型（STI） | ✅ 已實作 | 使用 Single Table Inheritance |
| FirstLoveAchievement | ✅ 已實作 | 被分配到至少一個 issue |
| CloseProjectAchievement | ✅ 已實作 | 關閉一個專案 |
| ItMustBeKiddingAchievement | ✅ 已實作 | 重新開啟一個專案 |
| AttachAPictureAchievement | ✅ 已實作 | 在專案中上傳圖片 |
| 成就列表頁面（Controller/View） | ✅ 已實作 | 顯示已解鎖與未解鎖成就 |
| 郵件通知 | ✅ 已實作 | 解鎖成就時寄信 |
| 自動註冊成就子類別 | ✅ 已實作 | 透過 `inherited` hook |
| i18n（en / zh-TW） | ✅ 已實作 | 但僅兩種語言 |

### 1.3 master 分支 vs develop 分支

**master 分支（v0.0.1）停留在非常早期的狀態**，缺少 controller、views、多數成就、以及從 Observer 轉 Callback 的重構。**develop 分支（v0.0.2）才是實際最新代碼**，但未合併回 master，也從未 release。

---

## 二、現有程式碼問題

### 2.1 嚴重 Bug

1. **`init.rb` 中有拼字錯誤（develop 分支）**
   - `Attachment.send(:inculde, ...)` → 應為 `:include`
   - 這會導致插件啟動時直接 crash

2. **`attachment_patch.rb` 引用不存在的方法**
   - `check_achievement` 中呼叫 `self.attachment`，但 Attachment model 本身不需要再呼叫 `attachment`，應該是 `self`

3. **`user_patch.rb` 使用已廢棄的 API**
   - `achievements.count(:conditions => { :type => achievement })` — `:conditions` 參數在 Rails 4+ 已移除
   - 應改用 `achievements.where(type: achievement.name).count`

4. **`project_patch.rb` 使用 `alias_method` 覆寫方式**
   - `alias_method :old_close, :close` 是脆弱的 monkey-patching，在 Rails 7 中應改用 `prepend` + `super`

5. **測試方法命名錯誤**
   - `achievement_test.rb` 中 `def user_should_not_be_nil` 缺少 `test_` 前綴，測試永遠不會被執行

### 2.2 過時的設計模式

| 問題 | 檔案 | 說明 |
|------|------|------|
| `unloadable` 關鍵字 | 多處 | Rails 7 中已無用且會造成問題 |
| `ActiveRecord::Observer` | init.rb (master) | Rails 4+ 已移出核心 |
| `ActiveRecord::Migration` 無版本號 | 001_create_achievements.rb | Rails 5+ 要求指定版本，如 `Migration[7.0]` |
| `send(:include, ...)` patch 模式 | init.rb | 應改用 `prepend` |
| `ActiveRecord::Base` 繼承 | achievement.rb | Redmine 6.0+ 使用 `ApplicationRecord` |
| `require_dependency` | init.rb (master) | Rails 7 Zeitwerk 模式下已移除 |
| `.deliver` 呼叫方式 | achievement.rb | Rails 4.2+ 應使用 `.deliver_later` 或 `.deliver_now` |

### 2.3 缺失功能

1. **無權限控管** — 沒有使用 Redmine 的 permission system，任何人都能看到成就頁面
2. **無管理介面** — 管理員無法啟用/停用特定成就、設定成就觸發條件
3. **無使用者個人頁面整合** — 成就未顯示在使用者 profile 頁面
4. **無 hook 整合** — 未使用 Redmine 的 view hooks 來嵌入成就資訊到既有頁面
5. **無 REST API** — 沒有提供 API endpoint 查詢成就
6. **無成就圖示/徽章系統** — 只有文字，沒有視覺化的徽章
7. **無成就進度追蹤** — 無法顯示「你完成了 3/10 個 issue」這類進度
8. **無成就分類/等級** — 所有成就都是同等級，缺少分類（如：銅/銀/金）
9. **無成就統計/排行榜** — 無法看到全站成就統計
10. **測試幾乎為零** — 只有一個（且未正確命名的）單元測試
11. **無 CI/CD 設定** — 沒有自動化測試或品質檢查
12. **缺少 uninstall migration** — 沒有提供移除插件時的 rollback migration

---

## 三、Redmine 6.0+ 相容性升級計畫

目前 Redmine 穩定版為 **6.0.8** 與 **6.1.1**（2026-01-06 發布），基於 **Rails 7.2** 與 **Ruby 3.1+**。

### 3.1 必要的框架升級

#### Phase 1：基礎相容性修復（優先度：最高）

1. **移除所有 `unloadable` 呼叫**
   - 影響檔案：`achievement.rb`, `user_patch.rb`, `mailer_patch.rb`, controller

2. **Migration 版本化**
   ```ruby
   # 舊：class CreateAchievements < ActiveRecord::Migration
   # 新：class CreateAchievements < ActiveRecord::Migration[7.0]
   ```

3. **Model 基底類別更新**
   ```ruby
   # 舊：class Achievement < ActiveRecord::Base
   # 新：class Achievement < ApplicationRecord（若 Redmine 6.0+）
   #     或保留 ActiveRecord::Base（若需向下相容 Redmine 5.x）
   ```

4. **移除 `require_dependency`，改用 Zeitwerk 自動載入**
   - 確保 `lib/` 下的檔案遵循 Zeitwerk 命名慣例
   - 在 `init.rb` 中使用 `Rails.autoloaders.main.push_dir` 或讓 Redmine 自動處理

5. **Patch 模式從 `include` 改為 `prepend`**
   ```ruby
   # 舊：
   # User.send(:include, PervokaAchievement::Patches::UserPatch)
   # 新：
   # User.prepend PervokaAchievement::Patches::UserPatch
   ```
   - Patch module 內部使用 `extend ActiveSupport::Concern` + `prepended do ... end`
   - 移除 `ClassMethods` / `InstanceMethods` 巢狀模組（直接定義方法即可）

6. **修復 `awarded?` 方法中過時的 query 語法**
   ```ruby
   # 舊：achievements.count(:conditions => { :type => achievement })
   # 新：achievements.where(type: achievement.name).exists?
   ```

7. **郵件發送方式更新**
   ```ruby
   # 舊：Mailer.achievement_unlocked(self).deliver
   # 新：Mailer.achievement_unlocked(self).deliver_now
   ```

#### Phase 2：Propshaft 與 Asset 管理

8. **CSS 檔案位置調整**
   - Redmine 6.0 使用 Propshaft 取代 Sprockets
   - 確認 `assets/stylesheets/main.css` 路徑是否仍被正確載入
   - 可能需要移至 `app/assets/stylesheets/`

#### Phase 3：修復已知 Bug

9. **修復 `init.rb` 中的 `:inculde` 拼字錯誤**
10. **修復 `attachment_patch.rb` 中的 `self.attachment` 引用**
11. **修復 `project_patch.rb` 中的 `alias_method` 覆寫** → 改用 `prepend` + `super`
12. **修復測試方法命名**（加上 `test_` 前綴）

---

## 四、功能增強計畫

### 4.1 短期目標（v0.5）

| 項目 | 說明 |
|------|------|
| **合併 develop 到 master** | 統一代碼基底 |
| **完成框架升級** | 相容 Redmine 6.0+ / Rails 7.2 |
| **權限系統整合** | 新增 `:view_achievements` 權限 |
| **使用者 Profile 整合** | 透過 Redmine view hooks 在使用者頁面顯示成就 |
| **完善測試** | 為每個成就撰寫單元測試，為 controller 撰寫 functional test |
| **成就圖示** | 為每個成就加上 SVG 圖示（配合 Redmine 6.0 的 Tabler icon 體系） |

### 4.2 中期目標（v0.7）

| 項目 | 說明 |
|------|------|
| **成就進度系統** | 支援多階段成就（如「完成 10/50/100 個 issue」） |
| **成就分類與等級** | 銅/銀/金分級 |
| **瀏覽器內通知** | 使用 Redmine 6.0 的通知機制，而非僅靠 email |
| **更多內建成就** | 新增 10+ 個常見成就（首次 commit、首次建立 wiki、首次提交 time entry 等） |
| **管理後台** | 管理員可啟用/停用成就、自訂觸發條件 |

### 4.3 長期目標（v1.0）

| 項目 | 說明 |
|------|------|
| **REST API** | 提供 JSON API 查詢成就 |
| **排行榜** | 全站成就統計與排名 |
| **自訂成就** | 管理員可透過 UI 定義新成就（不需寫程式） |
| **Webhook 整合** | 成就解鎖時可觸發外部 webhook |
| **多語言擴充** | 支援更多語言（ja, ko, de, fr 等） |

---

## 五、建議的開發順序

```
Step 1: 將 develop 分支合併到工作分支，以 develop 為基礎開始
         ↓
Step 2: 修復所有已知 Bug（拼字錯誤、過時 API 呼叫等）
         ↓
Step 3: 框架升級 — 移除 unloadable、Migration 版本化、prepend 模式
         ↓
Step 4: 在 Redmine 6.0 環境中驗證插件可正常安裝與運行
         ↓
Step 5: 補齊測試（unit test + functional test）
         ↓
Step 6: 新增權限控管與 view hook 整合
         ↓
Step 7: 加入成就圖示與視覺改善
         ↓
Step 8: Release v0.5（Redmine 6.0 compatible）
```

---

## 六、參考資源

- [Redmine 6.0.0 Release](https://www.redmine.org/news/147)
- [Redmine Plugin Tutorial](https://www.redmine.org/projects/redmine/wiki/plugin_tutorial)
- [Redmine Plugin Internals](https://www.redmine.org/projects/redmine/wiki/Plugin_internals)
- [Prepare for Redmine 6 — Checklist for Plugins](https://www.redmineadvisor.com/articles/6_0/checklist-themes-plugins-developer-before-redmine-6/)
- [Rails Observers (removed from core)](https://github.com/rails/rails-observers)
- [Redmine Hooks](https://www.redmine.org/projects/redmine/wiki/hooks)
- [Redmine Download（目前穩定版 6.0.8 / 6.1.1）](https://www.redmine.org/projects/redmine/wiki/download)
