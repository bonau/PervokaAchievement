# E2E Testing Guide

本文件說明 PervokaAchievement 的瀏覽器端對端（E2E）測試架構、運作原理，以及建置過程中獲得的實務經驗。

---

## 目錄

- [為什麼需要 E2E 測試](#為什麼需要-e2e-測試)
- [架構總覽](#架構總覽)
- [四個容器的角色](#四個容器的角色)
- [啟動流程時序圖](#啟動流程時序圖)
- [測試流程：7 個階段](#測試流程7-個階段)
- [截圖作為驗證證據](#截圖作為驗證證據)
- [關鍵設計決策與原理](#關鍵設計決策與原理)
- [建置過程學到的知識](#建置過程學到的知識)
- [執行方式](#執行方式)
- [故障排除](#故障排除)
- [檔案結構](#檔案結構)

---

## 為什麼需要 E2E 測試

PervokaAchievement 的既有測試（RSpec 單元/整合測試）驗證的是 model、controller、patch 各自的行為。但 v1.0 發行前，我們需要確認 **整條鏈路在真實瀏覽器中是否正確運作**：

```
使用者建立 Issue
  → IssuePatch#after_save 觸發
    → CreateFirstIssueAchievement.check_conditions_for
      → Achievement 寫入 DB + 郵件排程 + 事件發送
        → 下一次頁面載入時 ViewListener hook 注入 Toast HTML
          → 使用者看到 "Achievement Unlocked!" 通知
            → /achievements 顯示已解鎖成就 + 分數
              → /achievements/leaderboard 顯示排名
```

這條鏈路橫跨 9 個 patch、21 種成就類型、hook 系統、JavaScript 動畫、多個 controller 和 view。RSpec 單元測試無法覆蓋 **JS 動畫是否執行**、**CSS 是否正確渲染**、**頁面跳轉後 toast 是否出現** 等瀏覽器層面的行為。

E2E 測試透過 **真實的 Chrome 瀏覽器** 操作 Redmine，模擬使用者的完整操作流程，並在每個關鍵步驟 **截圖存檔** 作為視覺證據。

---

## 架構總覽

```
┌─────────────────────────────────────────────────────┐
│                  Docker Network                      │
│                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────────────┐ │
│  │ postgres │◄──│ redmine  │   │     chrome        │ │
│  │ (DB)     │   │ (App)    │◄──│ (Selenium+Chrome) │ │
│  └──────────┘   └──────────┘   └──────────────────┘ │
│                       ▲               ▲              │
│                       │               │              │
│                  ┌────┴───────────────┴──┐           │
│                  │       test            │           │
│                  │  (Capybara + RSpec)   │           │
│                  └───────────────────────┘           │
└─────────────────────────────────────────────────────┘
```

測試架構遵循 **Selenium Remote WebDriver** 模式：測試程式（Capybara）不在本機操控瀏覽器，而是透過 Selenium 協定，遠端指揮另一個容器中的 Chrome 來存取 Redmine。

---

## 四個容器的角色

### 1. `postgres` — 資料庫

- 映像：`postgres:15-alpine`
- 提供 Redmine 所需的 PostgreSQL 資料庫
- 容器啟動即可用，無需額外設定

### 2. `redmine` — 被測應用程式

- 映像：基於 `redmine:6.1`，自建 `Dockerfile.redmine`
- 安裝 PervokaAchievement plugin + 測試用 gem
- **關鍵**：使用自訂 entrypoint wrapper (`e2e-start.sh`)，在 server 啟動後自動載入 Redmine 預設資料（Tracker、Status、Role、Priority）

### 3. `chrome` — 瀏覽器引擎

- 映像：`selenium/standalone-chrome`
- 內含完整的 Chrome 瀏覽器 + Selenium WebDriver server
- 透過 Xvfb 提供虛擬顯示，讓 Chrome 可以正常渲染頁面
- 在 port 4444 提供 Selenium Remote WebDriver API
- `shm_size: 2g` 防止 Chrome 因 `/dev/shm` 不足而崩潰

### 4. `test` — 測試執行器

- 映像：基於 `ruby:3.2-slim`，自建 `Dockerfile.test`
- 安裝 Capybara、selenium-webdriver、RSpec
- 執行 `wait-and-test.sh`：先等待 Redmine 和 Selenium 就緒，再跑 RSpec
- 測試結束後截圖透過 `podman cp` 提取到宿主機

---

## 啟動流程時序圖

```
時間軸 →

postgres:  [啟動] [初始化 DB] [就緒 ✓]
                                │
redmine:   [啟動] [entrypoint: 產生 database.yml, db:migrate, plugins:migrate]
                  [啟動 Rails server ─────────────────────────────────────
                  │              [e2e-start.sh: curl 輪詢 /login]
                  │              [偵測到 server 就緒 ✓]
                  │              [rake redmine:load_default_data]
                  │              [預設資料載入完成 ✓]
                  │
chrome:    [啟動] [Selenium ready ✓]
                                │
test:      [啟動] [wait-and-test.sh: 輪詢 Redmine /login]
                  [Redmine 就緒 ✓]
                  [等待 10 秒讓預設資料載入]
                  [輪詢 Selenium /status]
                  [Selenium 就緒 ✓]
                  [執行 RSpec E2E 測試]
                  [測試完成 → 容器退出]
```

### 為什麼需要 `e2e-start.sh` wrapper？

官方 Redmine Docker image 的 entrypoint 會處理：database.yml 產生、db:migrate、plugins:migrate、啟動 Rails server。但它 **不會載入預設資料**（Tracker、Status 等）。

沒有 Tracker，就無法建立 Issue；沒有 Issue，就無法觸發成就。因此 `e2e-start.sh` 在 server 啟動後額外執行：

```bash
rake redmine:load_default_data REDMINE_LANG=en
```

這需要一個技巧：原始 entrypoint 透過 `exec` 啟動 server（取代了 shell process），所以我們不能在 entrypoint 之後追加指令。解決方式是 **在背景執行 entrypoint**，等待 server 就緒後再載入資料：

```bash
/docker-entrypoint.sh "$@" &     # 背景執行原始 entrypoint + server
SERVER_PID=$!
until curl -sf http://localhost:3000/login; do sleep 2; done
rake redmine:load_default_data    # server 就緒後載入預設資料
wait $SERVER_PID                  # 等待 server 進程
```

---

## 測試流程：7 個階段

測試以單一 RSpec example 實作，按順序執行 7 個階段。每個階段都有明確的斷言（expect）和截圖。

### Phase 1: Admin 登入

```ruby
login_as('admin', 'admin')
# Redmine 首次登入會強制改密碼
fill_in 'new_password', with: 'Admin12345!'
```

- 驗證：頁面出現「Sign out」連結
- 截圖：`01_admin_logged_in.png`
- **學習**：Redmine 新安裝後 admin 的 `must_change_passwd` 預設為 true，必須在測試流程中處理

### Phase 2: 建立專案

```ruby
visit '/projects/new'
fill_in 'project_name', with: 'E2E Test Project'
all('input[name="project[tracker_ids][]"]').each { |cb| cb.set(true) }
```

- 驗證：頁面顯示專案名稱
- 截圖：`02_project_created.png`
- **學習**：Redmine 新專案表單的 Tracker 勾選框在預設資料載入前不存在，需確保 `load_default_data` 在此步驟之前完成

### Phase 3: 建立第一個 Issue

```ruby
visit "/projects/e2e-test/issues/new"
fill_in 'issue_subject', with: 'My very first issue'
```

- **觸發鏈路**：Issue after_save → IssuePatch#check_achievement → CreateFirstIssueAchievement / BugHunterAchievement / NightOwlAchievement
- 驗證：頁面顯示 issue 標題
- 截圖：`03_issue_created.png`

### Phase 4: Toast 通知

```ruby
expect(page).to have_css('.achievement_toast')
toast_text = find('#achievement-toast-container').text
expect(toast_text).to include('Hello World')
```

- **原理**：Achievement 建立時 `notified_at` 為 null → 下一次頁面載入時 `view_layouts_base_body_bottom` hook 偵測到未通知的成就 → 注入 toast HTML + 設定 `notified_at`
- Toast JS 動畫在 6.5 秒後自動移除 DOM 元素，測試必須在此之前斷言
- 截圖：`04_achievement_toast.png`

### Phase 5: 成就儀表板

```ruby
visit '/achievements'
expect(page).to have_content('Hello World')
expect(page).to have_css('.achievement_entry.unlocked')
score = find('.score_value').text.to_i
expect(score).to be > 0
```

- 驗證：成就名稱、unlocked CSS class、分數 > 0
- 截圖：`05_achievements_dashboard.png`

### Phase 6: 排行榜

```ruby
visit '/achievements/leaderboard'
expect(page).to have_css('table.achievement_leaderboard tbody tr')
```

- 驗證：排行榜表格有至少一行資料
- 截圖：`06_leaderboard.png`

### Phase 7: Admin 成就管理

```ruby
visit '/admin/achievements'
expect(page).to have_content('Hello World')
expect(page).to have_content('First Love')
expect(page).to have_content('Problem Solver')
```

- 驗證：管理頁面列出多種成就類型
- 截圖：`07_admin_achievements.png`

---

## 截圖作為驗證證據

每個階段的 `take_screenshot` 呼叫透過 Selenium 協定要求遠端 Chrome 擷取目前頁面的 PNG 截圖。截圖儲存在容器內的 `/app/screenshots/`，測試結束後由 `run.sh` 的 cleanup 函數透過 `podman cp` 提取到宿主機的 `e2e/screenshots/`。

當測試失敗時，`after(:each)` hook 會自動擷取失敗畫面，檔名以 `FAIL_` 開頭。這對於除錯非常有用——你可以直接看到瀏覽器在失敗那一刻顯示了什麼。

---

## 關鍵設計決策與原理

### 為什麼選擇 Capybara + Selenium（而非 Playwright/Cypress）？

- 專案以 Ruby 為主，Capybara 是 Ruby 生態系的標準 E2E 工具
- RSpec 語法與既有測試一致，團隊不需學習新語法
- Selenium Remote WebDriver 模式天然適合容器化架構

### 為什麼 test 容器不直接內嵌 Chrome？

- **關注點分離**：test 容器只裝 Ruby + 測試 gem，chrome 容器處理瀏覽器
- **資源隔離**：Chrome 需要大量記憶體（`shm_size: 2g`），獨立容器更易控管
- **可替換性**：未來可切換 Firefox（`selenium/standalone-firefox`）而不改測試程式

### 為什麼用 `Capybara.run_server = false`？

E2E 測試中 Capybara 不需要自己啟動 Rack server——被測應用（Redmine）已經在另一個容器中運行。Capybara 只是透過 `app_host` 指定的 URL 發送請求。

### 為什麼截圖用 `podman cp` 而非 volume mount？

在 Podman Machine（Windows/WSL2）環境下，宿主機路徑無法直接掛載到容器。`podman cp` 不依賴路徑掛載，在所有 container runtime 下都能運作。

---

## 建置過程學到的知識

以下記錄建置 E2E 測試基礎設施時遇到的問題與解決方案，供未來維護參考。

### 1. Redmine Docker 不載入預設資料

**問題**：官方 `redmine:6.1` 映像的 entrypoint 處理 database.yml、db:migrate、plugins:migrate，但 **不會** 執行 `rake redmine:load_default_data`。沒有預設資料意味著系統中沒有 Tracker、Status、Role、Priority，因此無法建立 Issue。

**解決**：建立自訂 `Dockerfile.redmine`，用 wrapper entrypoint 在 server 啟動後自動載入。

### 2. Entrypoint 的 `exec` 語意

**問題**：原始 entrypoint 以 `exec "$@"` 結尾，這會用 `rails server` 進程取代 shell 進程。無法在 `exec` 之後追加指令。

**解決**：在 wrapper 中以 `&`（背景執行）呼叫原始 entrypoint，保留 shell 以便後續執行 rake 命令。

### 3. `SECRET_KEY_BASE` 環境變數作用域

**問題**：原始 entrypoint 在其進程空間中設定 `SECRET_KEY_BASE`（從 `REDMINE_SECRET_KEY_BASE` 轉換而來），但 wrapper 的 rake 命令在不同的進程空間，看不到這個變數。rake 因此報錯：`Missing secret_key_base for 'production' environment`。

**解決**：在 wrapper 中顯式設定 `export SECRET_KEY_BASE="${SECRET_KEY_BASE:-${REDMINE_SECRET_KEY_BASE:-e2e_fallback_key}}"`。

### 4. Podman vs Docker 相容性

**問題**：開發環境使用 Podman（而非 Docker），帶來數個差異：
- `docker-compose` v1 與 Podman 5.x 的 CNI 網路不相容（`cniVersion: 1.0.0` vs `0.4.0`）
- 短名稱映像（如 `postgres:15-alpine`）需要改為完整名稱（`docker.io/postgres:15-alpine`）
- Volume mount 在 Podman Machine（Windows/WSL2）環境下失敗：宿主 WSL distro 的路徑在 Podman Machine WSL distro 中不存在

**解決**：
- 使用 `podman-compose` 替代 `docker-compose`（原生支援 Podman）
- 映像名稱加上 `docker.io/` 前綴
- 放棄 volume mount，改用 `podman cp` 提取截圖

### 5. Redmine 首次登入強制改密碼

**問題**：Redmine 新安裝後 admin 使用者的 `must_change_passwd` 為 true。登入後會被強制導向 `/my/password`，無法直接操作其他功能。

**解決**：在測試 Phase 1 中偵測 `new_password` 欄位是否存在，若存在則自動填寫新密碼。

### 6. Toast 通知的時間窗口

**問題**：成就 toast 透過 JavaScript 在頁面載入 0ms 後加入 `show` class，6000ms 後加入 `fade_out` class，6500ms 後從 DOM 移除。如果 Capybara 的操作太慢，toast 可能在斷言前就已消失。

**解決**：
- 使用 `page.has_css?('.achievement_toast', wait: 5)` 讓 Capybara 等待元素出現（最多 5 秒）
- 若 toast 已消失，不視為測試失敗（Phase 5 的 dashboard 檢查仍能確認成就已解鎖）
- 截圖在斷言後立即執行，捕捉 toast 顯示的瞬間

### 7. Entrypoint `isLikelyRedmine` 判斷

**問題**：Redmine 的 entrypoint 透過 `$1`（CMD 的第一個參數）判斷是否執行 Redmine 相關設定。只有 `rails`、`rake`、`bundle exec` 才會觸發 database.yml 產生等關鍵步驟。如果用自訂的 `bash -c "..."` 作為 CMD，設定會被跳過。

**解決**：wrapper entrypoint 接收原始 CMD（`rails server -b 0.0.0.0`），原封不動地傳遞給 `/docker-entrypoint.sh "$@"`，確保 `$1 = rails` 觸發完整設定流程。

---

## 執行方式

### 快速啟動

```bash
cd e2e
./run.sh
```

`run.sh` 會自動偵測 `podman-compose` 或 `docker-compose`，建置映像、啟動所有服務、執行測試、提取截圖、清理容器。

### 手動步驟

```bash
cd e2e

# 建置映像
podman-compose build

# 啟動測試
podman-compose up --abort-on-container-exit --exit-code-from test

# 提取截圖
mkdir -p screenshots
podman cp e2e_test_1:/app/screenshots/. ./screenshots/

# 清理
podman-compose down
```

### 查看截圖

測試完成後，截圖存放在 `e2e/screenshots/`：

| 檔案 | 內容 |
|------|------|
| `01_admin_logged_in.png` | Admin 登入後的帳戶頁面 |
| `02_project_created.png` | 專案建立成功的設定頁面 |
| `03_issue_created.png` | Issue 建立後的顯示頁面 |
| `04_achievement_toast.png` | "Hello World" 成就解鎖 toast 通知 |
| `05_achievements_dashboard.png` | 成就儀表板（含已解鎖成就和分數） |
| `06_leaderboard.png` | 排行榜頁面 |
| `07_admin_achievements.png` | Admin 成就管理設定頁面 |
| `FAIL_*.png` | 測試失敗時的自動截圖（僅在失敗時產生） |

---

## 故障排除

### Redmine 啟動逾時

```
ERROR: Redmine did not become ready within 180s
```

- 檢查 postgres 是否正常啟動：`podman logs e2e_postgres_1`
- 檢查 redmine 日誌：`podman logs e2e_redmine_1`
- 常見原因：DB migration 失敗、plugin 相容性問題

### 找不到 Issue 表單欄位

```
Capybara::ElementNotFound: Unable to find field "issue_subject"
```

- 通常代表 Redmine 預設資料未載入（沒有 Tracker）
- 檢查 redmine 日誌中是否有 `E2E: ready` 訊息
- 確認 `SECRET_KEY_BASE` 環境變數正確傳遞

### Chrome 容器崩潰

```
session not created: Chrome failed to start
```

- 確認 `shm_size: 2g`（Chrome 需要足夠的共享記憶體）
- 檢查系統記憶體是否充足（Chrome + Redmine + PostgreSQL 至少需 2GB）

### Podman volume mount 失敗

```
Error: statfs /path/to/screenshots: no such file or directory
```

- 這是 Podman Machine（Windows/WSL2）的已知限制
- 目前架構已避免使用 volume mount，改用 `podman cp`

---

## 檔案結構

```
e2e/
├── docker-compose.yml          # 定義 4 個服務的組合
├── Dockerfile.redmine          # 自訂 Redmine 映像（含 default data 載入）
├── Dockerfile.test             # 測試執行器映像（Ruby + Capybara）
├── Gemfile                     # 測試用 gem（capybara, selenium-webdriver, rspec）
├── run.sh                      # 一鍵執行腳本
├── wait-and-test.sh            # 等待服務就緒後執行測試
├── .gitignore                  # 排除截圖 PNG 和 Gemfile.lock
├── screenshots/
│   └── .gitkeep                # 截圖輸出目錄（內容不進版控）
└── spec/
    ├── e2e_helper.rb           # Capybara Remote Chrome 驅動設定
    └── achievement_unlock_flow_spec.rb  # 7 階段 E2E 測試
```
