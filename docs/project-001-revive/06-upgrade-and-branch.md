# Redmine 6.1 升級、依賴更新與分支策略確立（2026-03-28）

> 本文記錄 project-001-revive 完成後的後續工作：
> 解決版本樹錯亂、升級所有 GitHub Actions 依賴、升級至 Redmine 6.1、確立 develop 分支策略。

---

## 一、版本樹狀態（作業前）

```
master  ←─── b1a9d82（含 improvement plan、release/0.1 merge）
                │
               （3 commits，develop 沒有）
                │
develop ←─── 0454172（比 master 多 35 個舊 feature commits）
```

問題：`feature/rspec-migration-and-ci` 已在 GitHub 以 PR #5 合併進 master（1be98fc），但本地 master 未 pull；develop 落後 master 且兩者雙向分歧。

---

## 二、依賴更新：GitHub Actions 版本升級

Dependabot 自動發出了 6 個 PR，評估後全部接受升級：

| PR | 內容 | 結果 |
|----|------|------|
| #7  | `docker/build-push-action` 5 → 7 | 合併 |
| #8  | `actions/checkout` 4 → 6 | 合併 |
| #9  | `actions/upload-artifact` 4 → 7 | 合併 |
| #10 | `docker/login-action` 3 → 4 | 合併 |
| #11 | `github/codeql-action` 3 → 4 | 合併 |
| #6  | `redmine` 5.1 → 6.1（Dockerfile） | 關閉，由 PR #12 取代 |

PR #6 被關閉的原因：直接合併只更新 Dockerfile，但同步更新 CI matrix 和 plugin 版本更合適，因此改用手動 PR 一次處理三件事。

---

## 三、Redmine 6.1 升級（PR #12）

### 異動內容

**`Dockerfile`**
```dockerfile
# 原
FROM redmine:5.1
# 改後
FROM redmine:6.1
```

**`.github/workflows/ci.yml`（CI matrix）**

```yaml
# 原
ruby: ['3.1', '3.2']
redmine: ['5.0', '5.1']
exclude:
  - ruby: '3.2'
    redmine: '5.0'

# 改後
ruby: ['3.1', '3.2', '3.3']
redmine: ['5.1', '6.1']
exclude:
  - ruby: '3.1'
    redmine: '6.1'   # Redmine 6.1 最低需求 Ruby 3.2+
  - ruby: '3.3'
    redmine: '5.1'   # 5.1 只測 3.1/3.2
```

新矩陣實際測試組合：
- Ruby 3.1 × Redmine 5.1
- Ruby 3.2 × Redmine 5.1
- Ruby 3.2 × Redmine 6.1
- Ruby 3.3 × Redmine 6.1

**`init.rb`（plugin 版本）**
```ruby
# 原
version '0.0.2'
# 改後
version '6.1.0'
```

版本號策略：plugin 主版本號與 Redmine 大版本對齊（本專案不在 production 運行，無向下相容顧慮）。

---

## 四、CI 修復：`unloadable` 與 Rails 6+ 不相容

PR #12 第一次 CI 跑時，Redmine 6.1 的兩個 matrix job 全部失敗：

```
NameError: unloadable
An error occurred while loading ./spec/controllers/achievements_controller_spec.rb.
```

**根因**：`unloadable` 是 Rails 2/3 的手動 code reloading 機制，Rails 6.0 正式移除。Redmine 6.1 基於 Rails 7.x，呼叫 `unloadable` 直接拋出 `NameError`。Redmine 5.x（Rails 6.1）雖已棄用但仍接受，所以 Redmine 5.1 的 job 沒有失敗。

**受影響的檔案（5 個）**：
- `app/controllers/achievements_controller.rb`
- `app/models/achievement.rb`
- `lib/pervoka_achievement/patches/mailer_patch.rb`
- `lib/pervoka_achievement/patches/project_patch.rb`
- `lib/pervoka_achievement/patches/user_patch.rb`

**修法**：直接刪除所有 `unloadable` 呼叫。Zeitwerk 自動處理 code reloading，不需要手動標記。

修復後 PR #12 全部 9 個 CI check 通過，合併。

---

## 五、分支策略確立

### 作業後分支結構

```
master  ← 保留穩定/release 狀態，不直接開發
develop ← 主要開發整合分支（所有 feature 在此聚合）
feature/* ← 從 develop 切出，PR 回 develop
```

### 同步流程（PR #13：master → develop）

1. master 包含所有最新內容後，建立 PR：`master → develop`
2. 合併後：`git log --oneline develop..master` 為空（完整同步）

### 開發流程（日後）

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature

# ... 開發、commit ...

git push origin feature/your-feature
# 開 PR，base 設為 develop
```

文件更新：`.github/CONTRIBUTING.md` 「提交程式碼」一節已更新，明確說明 feature branch 從 `develop` 切出，PR base 為 `develop`。

---

## 六、最終狀態

| 項目 | 值 |
|------|---|
| Plugin 版本 | 6.1.0 |
| 目標 Redmine 版本 | 5.1、6.1 |
| CI Ruby 版本 | 3.1、3.2、3.3 |
| CI 測試組合 | 4 組 |
| 主要開發分支 | `develop` |
| master 狀態 | 穩定，與 develop 完整同步 |
