# 專案復活計畫：總覽

> 記錄從 commit `2dd40d6` 起，將 PervokaAchievement Redmine 外掛「復活」的完整過程：
> 遷移測試框架、修復舊語法、建立 CI/CD，直到所有 CI check 通過。

---

## 時間軸概要

| 日期 | 階段 | 重要 commits / PRs |
|------|------|-------------|
| 2026-02-09 | 初始修復與測試補齊 | `e116487` `0454172` |
| 2026-02-11 | RSpec 遷移、Docker、CI 建立 | `40d38e7` → `9eb025d` |
| 2026-02-16 | 修補 CI 第一批失敗 | `b35b6e5` |
| 2026-02-18 | 修補 CI 第二批失敗（大量迭代） | `40eb906` → `3d90abf` → `88577e1` → `b869abb` → `ec5ba0f` |
| 2026-02-19 | 補寫過程文件 | `c465287` |
| 2026-03-28 | 依賴升級、Redmine 6.1 升級、分支策略確立 | PR #7–#11、PR #12、PR #13 |

---

## 各章節索引

| 文件 | 說明 |
|------|------|
| [02-rspec-migration.md](02-rspec-migration.md) | Minitest → RSpec 遷移過程與問題 |
| [03-ci-setup.md](03-ci-setup.md) | GitHub Actions CI/CD 建立與修補過程 |
| [04-app-bugs.md](04-app-bugs.md) | 應用程式本體 bug 修復記錄 |
| [05-retrospective.md](05-retrospective.md) | 反省：不必要的動作與未來可避免的問題 |
| [06-upgrade-and-branch.md](06-upgrade-and-branch.md) | Redmine 6.1 升級、依賴更新、分支策略確立（2026-03-28） |

---

## 最終成果（截至 2026-03-28）

- 測試框架：Minitest → RSpec（12 spec 檔，65 個測試案例）
- CI 矩陣：Ruby 3.1/3.2/3.3 × Redmine 5.1/6.1（4 組合）
- Plugin 版本：6.1.0（與 Redmine 大版本對齊）
- 所有 GitHub Actions workflow 通過（含 Redmine 6.1）
- Docker build 驗證可用（base image：redmine:6.1）
- 分支策略：`develop` 為主要開發分支，feature branch 從 develop 切出
