# 測試說明文件

## 概述

本專案已補齊所有必要的測試檔案，包括：

### Unit Tests (單元測試)

#### 成就模型測試
- `test/unit/achievement_test.rb` - 基礎成就模型測試
- `test/unit/attach_a_picture_achievement_test.rb` - 附加圖片成就測試
- `test/unit/close_project_achievement_test.rb` - 關閉專案成就測試
- `test/unit/first_love_achievement_test.rb` - 首次被指派議題成就測試
- `test/unit/it_must_be_kidding_achievement_test.rb` - 重新開啟專案成就測試

#### Patch 測試
- `test/unit/user_patch_test.rb` - 使用者補丁測試
- `test/unit/issue_patch_test.rb` - 議題補丁測試
- `test/unit/project_patch_test.rb` - 專案補丁測試
- `test/unit/attachment_patch_test.rb` - 附件補丁測試
- `test/unit/mailer_patch_test.rb` - 郵件補丁測試

### Functional Tests (功能測試)

- `test/functional/achievements_controller_test.rb` - 成就控制器測試

## 測試涵蓋範圍

### 成就模型測試涵蓋：
- 成就註冊機制
- 條件檢查邏輯
- 不重複頒發機制
- 成就解鎖條件

### Patch 測試涵蓋：
- 模組包含檢查
- 關聯關係驗證
- 回呼方法測試
- 方法覆寫驗證

### 控制器測試涵蓋：
- 頁面訪問權限
- 變數賦值驗證
- 已解鎖/可解鎖成就分類
- 使用者認證

## 如何執行測試

### 前置需求

1. 完整的 Redmine 環境
2. 本插件已安裝在 Redmine 的 `plugins` 目錄下
3. 已執行資料庫遷移

### 安裝步驟

```bash
# 1. 複製插件到 Redmine 的 plugins 目錄
cp -r /path/to/PervokaAchievement /path/to/redmine/plugins/pervoka_achievement

# 2. 進入 Redmine 根目錄
cd /path/to/redmine

# 3. 執行資料庫遷移
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=test
```

### 執行測試

在 Redmine 根目錄下執行：

```bash
# 執行所有插件測試
bundle exec rake redmine:plugins:test NAME=pervoka_achievement

# 或者只執行單元測試
bundle exec rake redmine:plugins:test:units NAME=pervoka_achievement

# 或者只執行功能測試
bundle exec rake redmine:plugins:test:functionals NAME=pervoka_achievement

# 執行特定的測試檔案
bundle exec ruby -I"lib:test" plugins/pervoka_achievement/test/unit/achievement_test.rb

# 執行特定的測試案例
bundle exec ruby -I"lib:test" plugins/pervoka_achievement/test/unit/achievement_test.rb -n test_user_should_not_be_nil
```

## 測試依賴

測試使用以下依賴：

- **ActiveSupport::TestCase** - Rails 測試框架
- **ActionController::TestCase** - Rails 控制器測試框架
- **Mocha** (可選) - 用於 stub 和 mock（部分測試需要）

如果 Redmine 環境未包含 Mocha，可透過以下方式安裝：

```bash
# 在 Redmine 的 Gemfile 中添加（如果尚未包含）
gem 'mocha'

# 然後執行
bundle install
```

## 已修正的問題

在補齊測試過程中，發現並修正了以下問題：

1. **init.rb 第 22 行**：`inculde` 拼寫錯誤，已修正為 `include`
2. **init.rb 第 22 行**：檢查條件錯誤，將 `Project.included_modules` 修正為 `Attachment.included_modules`
3. **attachment_patch.rb**：`check_achievement` 方法中將 `attachment` 修正為 `self`

## 語法檢查結果

所有檔案已通過 Ruby 語法檢查：

```
✓ init.rb
✓ 所有模型檔案 (5 個)
✓ 所有 patch 檔案 (5 個)
✓ 所有控制器檔案 (1 個)
✓ 所有測試檔案 (11 個)
```

## 測試最佳實踐

### 測試隔離
- 每個測試案例都應該獨立
- 使用 `setup` 和 `teardown` 方法確保測試環境的乾淨

### Fixtures
- 確保測試 fixtures 已正確載入
- 使用 `fixtures :users, :projects, :issues` 等宣告所需的測試資料

### 測試資料清理
- 在需要時清理相關成就記錄：`@user.achievements.where(type: 'XxxAchievement').destroy_all`
- 確保測試不會互相干擾

## 注意事項

1. 本測試套件需要在完整的 Redmine 環境中執行
2. 部分測試使用 Mocha 進行 mock 和 stub，確保已安裝
3. 測試執行前需要先執行測試資料庫遷移
4. 確保 Redmine 的測試環境已正確設定（`config/database.yml` 包含 test 環境設定）

## 疑難排解

### 找不到 fixtures

如果遇到 fixtures 錯誤，確保：
- Redmine 的測試資料庫已正確設定
- 已執行 `RAILS_ENV=test rake db:fixtures:load`

### 找不到模型或類別

確保：
- 插件已正確安裝在 `plugins/pervoka_achievement` 目錄
- init.rb 已正確載入所有必要的檔案

### Mocha 相關錯誤

如果遇到 `expects` 或 `stubs` 方法錯誤：
1. 確認 Gemfile 包含 `gem 'mocha'`
2. 在 test_helper.rb 中添加 `require 'mocha/minitest'`

## 進一步改進建議

1. **整合測試**：可以考慮添加整合測試來測試完整的使用者流程
2. **效能測試**：對於大量成就的情況，可以添加效能測試
3. **覆蓋率報告**：使用 SimpleCov 等工具產生測試覆蓋率報告
4. **持續整合**：設定 CI/CD 流程自動執行測試

## 聯絡資訊

如有測試相關問題，請參考：
- Redmine 官方文件：https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial
- 專案 GitHub：https://github.com/bonau/PervokaAchievement
