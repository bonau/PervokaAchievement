# RSpec 遷移過程記錄

## 背景

原有測試為 Minitest，位於 `test/` 目錄，僅有 2 個 test case。
目標：遷移至 RSpec 並補齊所有模型與 patch 的測試覆蓋。

---

## 遷移步驟（commit `40d38e7` `1db8604`）

1. 新增 `spec/` 目錄，依照模組結構建立：
   - `spec/models/` — Achievement 及各子類
   - `spec/controllers/` — AchievementsController
   - `spec/patches/` — 各 Patch 模組
2. 撰寫 `spec/spec_helper.rb`，設定 fixtures 路徑指向 Redmine 的 `test/fixtures/`
3. 刪除 `test/` 目錄與過時文件（`TEST_FILES_LIST.md` 等）

---

## 遷移後遇到的問題

### 問題 1：`fixture_path` vs `fixture_paths`（`5a4b1fd`）

**症狀**：Rails 6.1 使用 `fixture_paths=`（複數），舊版使用 `fixture_path=`（單數）。

**修法**：加入版本探測：
```ruby
if config.respond_to?(:fixture_paths=)
  config.fixture_paths = [...]
else
  config.fixture_path = ...
end
```

**根因**：沒有在本機用目標 Rails 版本先驗證 spec_helper 語法。

---

### 問題 2：Zeitwerk lazy-load 導致 `NoMethodError`（`0a6ae23`）

**症狀**：RSpec 對 achievement 子類設定 message expectation 時，Zeitwerk mutex 尚未初始化，拋出 `NoMethodError: undefined method 'synchronize'`。

**修法**：在 spec_helper 最前面加入：
```ruby
Rails.application.eager_load!
```

**根因**：test 環境預設 lazy-load，但 RSpec 的 expectation 設置時機早於 autoload 完成。

---

### 問題 3：Patch 在 test 環境未被 include（`6702dda`）

**症狀**：`UserPatch`、`IssuePatch` 等未被 include，導致測試中相關方法不存在。

**修法**：在 spec_helper 明確 include：
```ruby
[User, Issue, Mailer, Project, Attachment].zip([...patches...]).each do |klass, patch|
  klass.send(:include, patch) unless klass.included_modules.include?(patch)
end
```

**根因**：Redmine 的 `Rails.configuration.to_prepare` 在 test 環境不保證在 RSpec 載入前執行。

---

### 問題 4：Fixtures 宣告不完整，依賴關係缺失（`0a6ae23` `b869abb` `ec5ba0f`）

**症狀**：多次出現 `ActiveRecord::StatementInvalid`，因為缺少外鍵所需的 fixture 表。

**問題 fixture 列表（依修復順序）：**

| 規格檔 | 缺少的 fixture |
|--------|---------------|
| `issue_patch_spec.rb` | `projects_trackers`, `issue_priorities` → 後改為 `enumerations`, `issue_categories` |
| `first_love_achievement_spec.rb` | `enumerations`（原誤用 `issue_priorities`） |
| `mailer_patch_spec.rb` | `email_addresses` |

**根因**：Redmine fixture 依賴鏈複雜，沒有事先查明各 model 的完整關聯。反覆 CI 失敗後才逐一補齊。

---

### 問題 5：`check_conditions_for` 測試邏輯錯誤（`ec5ba0f`）

**症狀**：用 `FirstLoveAchievement.check_conditions_for` 測試「基礎機制」，但 `FirstLoveAchievement` 覆寫了方法，導致測試非預期行為。

**修法**：改用 `Achievement.check_conditions_for` 測試基底類別邏輯，並在 `awards when condition block returns true` 中補上 Mailer mock（因為 create 後會觸發 mail）。

---

### 問題 6：`after_save` callback 測試建立新物件失敗（`0a6ae23`）

**症狀**：直接 `Issue.new(...).save!` 因缺少大量關聯欄位而失敗。

**修法**：改用已存在的 fixture 物件（`Issue.find(1)`）呼叫 `save!`，只驗證 callback 有被呼叫。

**學習**：測試 callback 時優先使用 fixture 現有資料，避免手動建構完整物件。
