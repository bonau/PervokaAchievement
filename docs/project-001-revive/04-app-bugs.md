# 應用程式本體 Bug 修復記錄

這些是在遷移測試與 CI 過程中，發現原始程式碼本身的問題。

---

## Bug 1：`Achievement.inherited` 未呼叫 `super`（`3d90abf`）

**檔案**：`app/models/achievement.rb`

**症狀**：子類繼承 `Achievement` 時，`ActiveRecord::Base.inherited` 未被呼叫，導致 ActiveRecord 無法正確初始化子類（table 綁定、reflection 等）。

**修法**：
```ruby
def self.inherited(base)
  super   # 新增
  Achievement.registered_achievements << base
end
```

**影響**：沒有 `super` 的話，所有 Achievement 子類的 ActiveRecord 功能都不完整，是嚴重的潛在 bug。

---

## Bug 2：`user_patch.rb` 使用 Rails 2.x 語法（`40f335d`）

**檔案**：`lib/pervoka_achievement/patches/user_patch.rb`

**症狀**：`:conditions =>` hash 是 Rails 2.x 的 ActiveRecord 寫法，Rails 6.x 已移除。

**修法**：
```ruby
# 修前
achievements.count(:conditions => { :type => achievement }) > 0
# 修後
achievements.where(type: achievement.to_s).exists?
```

---

## Bug 3：`deliver` vs `deliver_now` vs `deliver_later` 混亂（多個 commits）

**檔案**：`app/models/achievement.rb`

這個 bug 被反覆修改，是整個過程中最混亂的部分：

| Commit | 修改 | 理由 |
|--------|------|------|
| `40f335d` | `deliver` → `deliver_later` | Rails 4+ 廢棄 `deliver` |
| `0a6ae23` | `deliver_later` → `deliver_now` | test 環境 async 不好測 |
| `b869abb` | `deliver_now` → `deliver_later` | 確認 test 環境用 mock，生產應非同步 |

**最終結論**：生產程式碼應使用 `deliver_later`；測試中用 mock 取代實際寄送，不應因測試需求而降級到 `deliver_now`。

---

## Bug 4：`Mailer.achievement_unlocked` 呼叫參數錯誤（`88577e1`）

**症狀**：原始程式碼呼叫 `Mailer.achievement_unlocked(self)` 只傳一個參數，但 MailerPatch 定義的方法簽名是 `achievement_unlocked(user, achievement)`，需要兩個參數。

**修法**：改為 `Mailer.achievement_unlocked(user, self)`。

---

## Bug 5：`AchievementsController` 缺少 `require_login`（`88577e1`）

**症狀**：Controller 未呼叫 `require_login`，導致未登入使用者可以存取成就列表，功能設計上應該要求登入。

**修法**：加入 `before_action :require_login`。

---

## Bug 6：init.rb 手動 require 路徑錯誤（初期，`e116487`）

**症狀**：`init.rb` 使用 `require` 載入 patch 檔時，路徑未涵蓋子目錄，且與 Zeitwerk 衝突。

**最終修法**（`977e483`）：完全移除手動 require，交由 Zeitwerk 處理。
