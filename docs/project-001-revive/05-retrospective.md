# 反省：不必要的動作與未來可避免的問題

---

## 一、不必要或可合併的動作

### 1. `deliver` / `deliver_now` / `deliver_later` 反覆修改（3 個 commits）

`40f335d` → `0a6ae23` → `b869abb` 三個 commit 都在改同一行。

**根因**：沒有在一開始就決定好「生產用 `deliver_later`，測試用 mock」的策略，導致為了讓 test 通過而改動生產程式碼，之後又改回來。

**應該怎麼做**：先確認 Mailer mock 策略，再決定 production 用的 API，兩件事一次做對。

---

### 2. fixture 宣告缺失被多次修補（`0a6ae23` `b869abb` `ec5ba0f`）

三個不同 commit 分別補上缺失的 fixtures（`enumerations`、`issue_categories`、`email_addresses`）。

**根因**：撰寫 spec 時沒有事先查明 model 的完整關聯鏈，完全依賴 CI 失敗的錯誤訊息來補。

**應該怎麼做**：撰寫 spec 前，先用 `Issue.reflect_on_all_associations` 或看 Redmine 原始碼確認所有直接/間接依賴的 fixture。

---

### 3. `PR_DESCRIPTION.md` 遺留在 repo 中（`88577e1`）

`PR_DESCRIPTION.md` 是為了 `gh pr create --body-file` 而產生的臨時檔案，不應該 commit 進 repo。

**應該怎麼做**：用 heredoc 或臨時檔案建立 PR 後立即刪除，或列入 `.gitignore`。

---

### 4. 大量文件在 CI 穩定前就先建立（`9eb025d` `f55dd93` `3f94172` `171b14e`）

CONTRIBUTING.md、CI/CD guide、README badges、Issue/PR templates 都在 2026-02-11 CI 建立的同一天完成，但當時 CI 根本還沒通過（後續 2/16、2/18 還有大量修補）。

**結果**：文件中描述的「CI 通過」狀態與實際不符。

**應該怎麼做**：先讓 CI 全部通過，再補文件。文件應反映穩定後的狀態。

---

### 5. `init.rb` 的 glob pattern 被改了兩次後才全刪（`b6487bb` → `977e483`）

先改成 `**/*.rb`，下一個 commit 又整個刪掉。可以直接在 `b6487bb` 時就評估是否要刪除，一步到位。

---

### 6. 測試矩陣 `include` → `exclude` 概念混淆（`70de5c2` → `b6487bb`）

初版用 `include` 只指定 2 組，但矩陣宣告了 4 組，邏輯上是矛盾的（`include` 是「追加」不是「限制」）。
應該一開始就用 `exclude` 排除不相容組合。

---

## 二、未來可避免的問題

### 問題類型 A：測試環境知識不足

| 問題 | 根因 | 預防方法 |
|------|------|---------|
| Zeitwerk lazy-load 干擾 RSpec | 不熟悉 Redmine/Rails test env 的 autoload 行為 | 建立 spec_helper 時就加入 `eager_load!`，這是 Redmine plugin 的標準做法 |
| Patch 未 include | `to_prepare` 在 test env 不保證順序 | spec_helper 樣板中預設包含手動 include patches 的步驟 |
| `fixture_path` vs `fixture_paths` | Rails 版本差異未確認 | 撰寫 spec_helper 時查 target Rails 版本的 RSpec Rails 文件 |

---

### 問題類型 B：CI 設定知識不足

| 問題 | 根因 | 預防方法 |
|------|------|---------|
| `rspec_junit_formatter` 缺失 | 只在 `--format` 用到卻忘了加 gem | 使用 formatter 前先確認 gem 已在 Gemfile 中 |
| `docker-compose` vs `docker compose` | 不知道新版 Docker CLI 已廢棄獨立 binary | 使用 `docker compose`（plugin 形式），或在 CI 安裝前確認版本 |
| `secrets` 不能在 `if` 比較 | GitHub Actions secrets 的限制不熟悉 | 改用 `github.event_name` 等 context 變數控制條件 |
| migration 未指定版本 | Rails 6+ 對 migration 版本的要求 | 建立 migration 時永遠加上 `[X.Y]` 版本號 |

---

### 問題類型 C：應用程式設計問題

| 問題 | 根因 | 預防方法 |
|------|------|---------|
| `inherited` 未呼叫 `super` | 覆寫 Ruby hook method 時忘記呼叫 super | 覆寫任何繼承自框架的 hook 時，預設先加 `super` |
| Rails 2.x 語法殘留 | 原始碼年代久遠，未更新 | 升級 Rails 版本時跑 deprecation warning 並逐一修正 |
| Mailer 呼叫參數不匹配 | Patch 新增的方法簽名與呼叫端不一致 | 撰寫 patch 時確認呼叫端與方法簽名一致，或補充整合測試 |

---

## 三、核心教訓

1. **CI 穩定先，文件後**：在 CI 全部通過之前，不要大量產出描述「現狀」的文件。

2. **測試策略先於實作**：撰寫測試前先決定 mock 邊界（哪些要 mock、哪些用真實物件），避免因測試需求反覆修改生產程式碼。

3. **Fixture 依賴要完整調查**：Redmine 的 fixture 依賴鏈深，先查清楚再動手，不要依賴 CI 錯誤訊息逐一補齊。

4. **一次改對，不要試錯迭代**：`deliver_later` 的三次修改、glob pattern 的兩次修改，都是可以事先思考清楚避免的。每個 commit 應該基於理解而非猜測。

5. **熟悉目標環境再動手**：Redmine plugin 的 test 環境有特殊需求（Zeitwerk、patch include 時機），事先閱讀 Redmine plugin 開發文件可以省去大量試錯。
