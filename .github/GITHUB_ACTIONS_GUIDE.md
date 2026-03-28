# GitHub Actions CI/CD 指南

本文件說明 PervokaAchievement 專案的 GitHub Actions 工作流程。

## 📋 目錄

- [工作流程概覽](#工作流程概覽)
- [CI 工作流程](#ci-工作流程)
- [CodeQL 安全掃描](#codeql-安全掃描)
- [Release 工作流程](#release-工作流程)
- [其他自動化](#其他自動化)
- [本地測試](#本地測試)
- [疑難排解](#疑難排解)

## 工作流程概覽

### 📊 主要工作流程

| 工作流程 | 觸發條件 | 用途 |
|---------|---------|------|
| **CI** | Push/PR 到 develop/main | 執行測試、語法檢查、Docker 建置 |
| **CodeQL** | Push/PR/定時 | 安全性程式碼掃描 |
| **Release** | 推送 tag (v*) | 建立 GitHub Release 和 Docker 映像 |
| **Stale** | 每日定時 | 標記和關閉過期的議題/PR |
| **Dependabot** | 每週定時 | 自動更新依賴 |

## CI 工作流程

檔案：`.github/workflows/ci.yml`

### 測試任務

執行 RSpec 測試套件，支援多版本矩陣測試。

#### 測試矩陣

```yaml
Ruby: [3.1, 3.2]
Redmine: [5.0, 5.1]
```

#### 執行步驟

1. **Checkout Redmine**：下載指定版本的 Redmine
2. **Checkout Plugin**：下載 plugin 程式碼
3. **Setup Ruby**：安裝指定版本的 Ruby
4. **Setup Database**：配置 PostgreSQL 測試資料庫
5. **Install Dependencies**：安裝 gem 依賴
6. **Setup Database**：執行資料庫遷移
7. **Run RSpec Tests**：執行測試套件
8. **Upload Results**：上傳測試結果

#### 服務容器

```yaml
services:
  postgres:
    image: postgres:15-alpine
    env:
      POSTGRES_USER: redmine
      POSTGRES_PASSWORD: redmine
      POSTGRES_DB: redmine_test
```

### 語法檢查任務

檢查所有 Ruby 檔案的語法正確性。

```bash
find . -name "*.rb" -exec ruby -c {} \;
```

同時檢查是否有除錯語句殘留：
- `binding.pry`
- `debugger`
- `byebug`

### Lint 任務

使用 RuboCop 進行程式碼風格檢查。

安裝的 gems：
- `rubocop`
- `rubocop-rails`
- `rubocop-rspec`

### Docker 建置任務

測試 Docker 映像是否能成功建置。

使用功能：
- Docker Buildx
- GitHub Actions Cache

## CodeQL 安全掃描

檔案：`.github/workflows/codeql.yml`

### 執行時機

- 推送到 develop/main 分支
- Pull Request
- 每週一定時掃描

### 掃描語言

- Ruby

### 功能

- 自動掃描安全漏洞
- 檢測常見的程式碼問題
- 產生安全性報告

## Release 工作流程

檔案：`.github/workflows/release.yml`

### 觸發條件

推送符合 `v*` 格式的 tag（例如：`v0.0.3`）

### 建立 Release 任務

#### 執行步驟

1. **Generate Changelog**：自動產生變更日誌
2. **Create Release Archive**：打包 tar.gz 和 zip 檔案
3. **Create GitHub Release**：建立 GitHub Release
4. **Attach Files**：附加發布檔案

#### 變更日誌格式

```markdown
## Changes in this Release

- commit message 1 (hash1)
- commit message 2 (hash2)

## Installation
[安裝說明]

## Docker Installation
[Docker 安裝說明]
```

### 發布 Docker 映像任務

#### 映像位置

- GitHub Container Registry: `ghcr.io/[username]/pervoka-achievement`
- Docker Hub (可選): 需要設定 secrets

#### 標籤策略

```yaml
tags:
  - latest (for default branch)
  - v1.0.0 (exact version)
  - v1.0 (minor version)
  - v1 (major version)
```

### 需要的 Secrets

#### 可選（Docker Hub）

```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_TOKEN=your_token
```

GitHub Container Registry 不需要額外設定。

## 其他自動化

### Stale Bot

檔案：`.github/workflows/stale.yml`

- **議題**：60 天無活動後標記為 stale，7 天後關閉
- **PR**：30 天無活動後標記為 stale，7 天後關閉
- **豁免標籤**：pinned, security, bug

### Dependabot

檔案：`.github/dependabot.yml`

自動監控並更新：
- GitHub Actions 版本
- Docker 基礎映像版本

每週一自動檢查並建立 PR。

## 本地測試

### 在提交前執行 CI 檢查

```bash
# 1. 語法檢查
find . -name "*.rb" -not -path "./vendor/*" -exec ruby -c {} \;

# 2. RuboCop
rubocop

# 3. RSpec 測試
bundle exec rspec spec

# 4. Docker 建置測試
docker build -t test .
```

### 使用 Act 本地執行 GitHub Actions

安裝 [act](https://github.com/nektos/act)：

```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

執行工作流程：

```bash
# 執行 push 事件
act push

# 執行特定工作流程
act -W .github/workflows/ci.yml

# 執行特定 job
act -j test
```

## 疑難排解

### 測試失敗

1. **檢查矩陣組合**
   - 確認 Ruby 和 Redmine 版本相容
   - 查看失敗的具體矩陣組合

2. **資料庫連線問題**
   ```yaml
   # 確認 PostgreSQL 服務正常啟動
   services:
     postgres:
       options: >-
         --health-cmd pg_isready
         --health-interval 10s
   ```

3. **依賴安裝失敗**
   - 檢查 Gemfile.local 是否正確
   - 確認 bundle install 的參數

### Docker 建置失敗

1. **檢查 Dockerfile 語法**
   ```bash
   docker build --no-cache -t test .
   ```

2. **清除快取**
   - 在 GitHub Actions 中手動清除快取
   - 設定 `cache-from: type=gha` 失效

3. **基礎映像問題**
   - 確認 `redmine:5.1` 映像可用
   - 檢查網路連線

### Release 失敗

1. **檢查 tag 格式**
   ```bash
   # 正確格式
   git tag v0.0.3
   git push origin v0.0.3
   
   # 錯誤格式
   git tag 0.0.3  # 缺少 v 前綴
   ```

2. **檢查 permissions**
   ```yaml
   permissions:
     contents: write  # 需要寫入權限
   ```

3. **Secrets 設定**
   - 確認 `GITHUB_TOKEN` 可用（自動提供）
   - Docker Hub secrets 正確設定（如需要）

### CodeQL 掃描問題

1. **語言設定**
   ```yaml
   # 確認掃描正確的語言
   matrix:
     language: [ 'ruby' ]
   ```

2. **掃描範圍**
   - 排除 vendor/ 和測試檔案
   - 使用 `.github/codeql/codeql-config.yml` 自訂

## 狀態徽章

在 README.md 中加入狀態徽章：

```markdown
[![CI](https://github.com/[username]/PervokaAchievement/workflows/CI/badge.svg)](https://github.com/[username]/PervokaAchievement/actions/workflows/ci.yml)

[![CodeQL](https://github.com/[username]/PervokaAchievement/workflows/CodeQL%20Analysis/badge.svg)](https://github.com/[username]/PervokaAchievement/actions/workflows/codeql.yml)
```

## 進階配置

### 平行測試

加速測試執行：

```yaml
- name: Run RSpec Tests
  run: |
    bundle exec rspec spec --format progress --format RspecJunitFormatter --out tmp/rspec.xml
  env:
    PARALLEL_WORKERS: 4
```

### 測試覆蓋率

整合 SimpleCov：

```ruby
# spec/spec_helper.rb
require 'simplecov'
SimpleCov.start 'rails'
```

上傳到 Codecov：

```yaml
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/coverage.xml
```

### 快取優化

加速依賴安裝：

```yaml
- name: Cache gems
  uses: actions/cache@v3
  with:
    path: vendor/bundle
    key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
```

## 最佳實踐

1. **保持工作流程簡潔**
   - 一個工作流程專注一件事
   - 使用可重用的 actions

2. **使用矩陣策略**
   - 測試多個版本組合
   - 快速發現相容性問題

3. **善用快取**
   - 快取依賴安裝
   - 快取 Docker 層

4. **保護敏感資訊**
   - 使用 GitHub Secrets
   - 不要在日誌中輸出機密

5. **及時更新**
   - 使用 Dependabot
   - 定期更新 actions 版本

## 相關資源

- [GitHub Actions 文件](https://docs.github.com/en/actions)
- [Ruby Setup Action](https://github.com/ruby/setup-ruby)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [CodeQL Action](https://github.com/github/codeql-action)

---

**更新日期**：2026-02-09  
**維護者**：PervokaAchievement Team
