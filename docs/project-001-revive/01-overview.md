# 專案復活計畫：總覽

> 記錄從 commit `2dd40d6` 起，將 PervokaAchievement Redmine 外掛「復活」的完整過程：
> 遷移測試框架、修復舊語法、建立 CI/CD，直到所有 CI check 通過。

---

## 時間軸概要

| 日期 | 階段 | 重要 commits |
|------|------|-------------|
| 2026-02-09 | 初始修復與測試補齊 | `e116487` `0454172` |
| 2026-02-11 | RSpec 遷移、Docker、CI 建立 | `40d38e7` → `9eb025d` |
| 2026-02-16 | 修補 CI 第一批失敗 | `b35b6e5` |
| 2026-02-18 | 修補 CI 第二批失敗（大量迭代） | `40eb906` → `3d90abf` → `88577e1` → `b869abb` → `ec5ba0f` |
| 2026-02-19 | 補寫過程文件 | `c465287` |

---

## 各章節索引

| 文件 | 說明 |
|------|------|
| [02-rspec-migration.md](02-rspec-migration.md) | Minitest → RSpec 遷移過程與問題 |
| [03-ci-setup.md](03-ci-setup.md) | GitHub Actions CI/CD 建立與修補過程 |
| [04-app-bugs.md](04-app-bugs.md) | 應用程式本體 bug 修復記錄 |
| [05-retrospective.md](05-retrospective.md) | 反省：不必要的動作與未來可避免的問題 |

---

## 最終成果

- 測試框架：Minitest → RSpec（12 spec 檔，65 個測試案例）
- CI 矩陣：Ruby 3.1/3.2 × Redmine 5.0/5.1（3 組合，排除不相容的 Ruby 3.2 + Redmine 5.0）
- 所有 GitHub Actions workflow 通過
- Docker build 驗證可用
