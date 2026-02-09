# 測試檔案清單

## 測試檔案結構

```
test/
├── test_helper.rb                                    # 測試輔助工具
├── functional/
│   └── achievements_controller_test.rb               # 成就控制器測試 (8 tests) ✨ 已更新
└── unit/
    ├── achievement_test.rb                           # 基礎成就模型測試 (13 tests) ✨ 已更新
    ├── attach_a_picture_achievement_test.rb          # 附加圖片成就測試 (4 tests) ✅ 新增
    ├── attachment_patch_test.rb                      # 附件補丁測試 (3 tests) ✅ 新增
    ├── close_project_achievement_test.rb             # 關閉專案成就測試 (4 tests) ✅ 新增
    ├── first_love_achievement_test.rb                # 首次被指派議題成就測試 (4 tests) ✅ 新增
    ├── issue_patch_test.rb                           # 議題補丁測試 (4 tests) ✅ 新增
    ├── it_must_be_kidding_achievement_test.rb        # 重新開啟專案成就測試 (4 tests) ✅ 新增
    ├── mailer_patch_test.rb                          # 郵件補丁測試 (6 tests) ✅ 新增
    ├── project_patch_test.rb                         # 專案補丁測試 (6 tests) ✅ 新增
    └── user_patch_test.rb                            # 使用者補丁測試 (7 tests) ✅ 新增
```

## 快速參考

### 執行所有測試
```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=pervoka_achievement
```

### 執行單一測試檔案
```bash
# 範例：執行成就模型測試
bundle exec ruby -I"lib:test" plugins/pervoka_achievement/test/unit/achievement_test.rb
```

### 執行特定測試案例
```bash
# 範例：執行特定的測試方法
bundle exec ruby -I"lib:test" plugins/pervoka_achievement/test/unit/achievement_test.rb \
  -n test_user_should_not_be_nil
```

## 測試統計

| 類別 | 檔案數 | 測試案例數 | 狀態 |
|------|--------|------------|------|
| 單元測試 - 成就模型 | 5 | 30 | ✅ |
| 單元測試 - Patch | 5 | 30 | ✅ |
| 功能測試 | 1 | 8 | ✅ |
| **總計** | **11** | **68** | ✅ |

## 測試對應關係

| 測試檔案 | 測試對象 | 位置 |
|---------|---------|------|
| achievement_test.rb | Achievement | app/models/achievement.rb |
| attach_a_picture_achievement_test.rb | AttachAPictureAchievement | app/models/attach_a_picture_achievement.rb |
| close_project_achievement_test.rb | CloseProjectAchievement | app/models/close_project_achievement.rb |
| first_love_achievement_test.rb | FirstLoveAchievement | app/models/first_love_achievement.rb |
| it_must_be_kidding_achievement_test.rb | ItMustBeKiddingAchievement | app/models/it_must_be_kidding_achievement.rb |
| user_patch_test.rb | UserPatch | lib/pervoka_achievement/user_patch.rb |
| issue_patch_test.rb | IssuePatch | lib/pervoka_achievement/issue_patch.rb |
| project_patch_test.rb | ProjectPatch | lib/pervoka_achievement/project_patch.rb |
| attachment_patch_test.rb | AttachmentPatch | lib/pervoka_achievement/attachment_patch.rb |
| mailer_patch_test.rb | MailerPatch | lib/pervoka_achievement/mailer_patch.rb |
| achievements_controller_test.rb | AchievementsController | app/controllers/achievements_controller.rb |

## 相關文件

- 📖 [測試執行說明](TEST_INSTRUCTIONS.md) - 詳細的測試執行指南
- 📊 [測試總結報告](TEST_SUMMARY.md) - 完整的測試補齊報告
- 📘 [README](README.md) - 專案主要說明文件

## 圖例

- ✅ 新增的測試檔案
- ✨ 更新並擴充的測試檔案
- 📖 說明文件
- 📊 報告文件
