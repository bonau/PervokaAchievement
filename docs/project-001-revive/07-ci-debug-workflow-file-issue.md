# CI 除錯：GitHub Actions「workflow file issue」診斷技巧

## 問題描述

每次 push 到任何 branch，都會收到來自 GitHub 的失敗通知 email：

```
[bonau/PervokaAchievement] Run failed: .github/workflows/release.yml - develop (a1f31e1)
```

奇怪的是，`release.yml` 的觸發條件是 `on: push: tags: v*`，不應該在 branch push 時被觸發。

---

## 診斷流程

### Step 1：確認 run 的狀態

```bash
gh run list --workflow=release.yml --limit 5
```

觀察到：
- 所有 run 的 duration 都是 **0 秒**
- jobs 數量為 **0**
- 每次都是 branch push 觸發，而非 tag push

```bash
gh run view <run-id> --json conclusion,event,headBranch,status,jobs
# → {"jobs":[], "conclusion":"failure", "event":"push", ...}
```

**關鍵線索**：`jobs: []` 代表 GitHub 連一個 job 都沒有建立，workflow 在排程階段就失敗了。

### Step 2：理解「workflow file issue」的含義

GitHub 在以下情況會對每次 push 產生一個合成的 failed run，而非真正執行 workflow：

> 當 workflow 檔案本身存在問題（語法錯誤、無效的 action 引用、不合法的 expression），GitHub 會偵測並以 failed run 的形式通知維護者，即使該 push 並不符合 workflow 的觸發條件。

這解釋了為什麼 `tags: v*` 過濾器完全沒有作用——workflow 根本未進入觸發判斷，就在檔案解析階段失敗了。

### Step 3：縮小可疑範圍

對照同樣有 Docker 步驟但**正常運作**的 `ci.yml`，列出 `release.yml` 獨有的 action 與語法：

| 項目 | release.yml 獨有 |
|------|-----------------|
| action | `softprops/action-gh-release@v1` |
| action | `docker/login-action@v4` |
| action | `docker/metadata-action@v5` |
| 語法 | `if: ${{ secrets.DOCKERHUB_USERNAME }}` |

逐一驗證 action 版本是否存在（可用 `gh api repos/<owner>/<repo>/tags` 查詢），確認四個 action 版本均存在。

### Step 4：找出根本原因

問題出在：

```yaml
        if: ${{ secrets.DOCKERHUB_USERNAME }}
```

**GitHub Actions 不允許在 `if:` 條件中使用 `secrets` context。**

Runner 在解析 workflow 檔案時會回報：

```
Unrecognized named-value: 'secrets'
```

這是一個 **parse-time error**，發生在 job 被排程之前，因此造成 `jobs: []` 的狀態。

---

## 修法

將 secret 先 map 到 job-level 的 `env`，再用 `env` context 做條件判斷：

```yaml
  publish-docker:
    env:
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}  # ← job 層級 map

    steps:
      - name: Log in to Docker Hub
        uses: docker/login-action@v4
        with:
          username: ${{ env.DOCKERHUB_USERNAME }}             # ← 改用 env
          password: ${{ secrets.DOCKERHUB_TOKEN }}
        if: env.DOCKERHUB_USERNAME != ''                      # ← env context 合法
```

`env` context 在 `if:` 條件中是合法的，且可以正確進行空字串判斷。

---

## 重點整理

### 診斷 GitHub Actions 的判斷流程

```
push 發生
  └─ GitHub 解析所有 .github/workflows/*.yml
       ├─ 解析失敗（parse-time error）
       │    └─ 產生 failed run（jobs: [], duration: 0s）
       │         觸發失敗通知 email（即使 push 不符合 trigger 條件）
       └─ 解析成功
            └─ 檢查 trigger 條件是否符合
                 ├─ 符合 → 建立 jobs，正常執行
                 └─ 不符合 → 靜默略過，不產生任何 run
```

### 快速診斷 checklist

| 症狀 | 可能原因 |
|------|---------|
| `jobs: []`，duration 0s | Workflow 檔案有 parse-time error |
| 不符合 trigger 卻被觸發 | 同上，GitHub 用 failed run 替代通知機制 |
| 每次任何 branch push 都失敗 | 檔案解析錯誤，與 trigger 條件無關 |

### 常見的 parse-time 錯誤

- `if:` 條件使用了 `secrets` context（應改用 `env` context）
- `uses:` 引用了不存在的 action 版本
- YAML 縮排或語法錯誤
- 不合法的 expression 語法（如 `${{ }}` 包裝了不支援的 context）

### `secrets` vs `env` context 使用原則

| 使用場景 | 正確做法 |
|---------|---------|
| step `with:` 傳入 secret 值 | `${{ secrets.MY_SECRET }}` ✓ |
| step `if:` 判斷 secret 是否存在 | 先在 job/step env map，再用 `env.VAR != ''` ✓ |
| job `if:` 判斷 secret | 同上，或改用 repository variable (`vars` context) |
| `run:` 步驟中使用 secret | 透過 `env:` 傳入環境變數 ✓ |
