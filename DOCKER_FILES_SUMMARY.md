# Docker 配置檔案總結

## 📦 已建立的檔案清單

### 核心配置檔案

| 檔案名稱 | 大小 | 說明 |
|---------|------|------|
| `Dockerfile` | 2.0 KB | Redmine + Plugin 的容器映像定義 |
| `docker-compose.yml` | 2.1 KB | 多容器編排配置（Redmine + PostgreSQL） |
| `.env.example` | 369 B | 環境變數範本 |
| `.dockerignore` | ~200 B | Docker 建置時忽略的檔案 |

### 輔助檔案

| 檔案名稱 | 大小 | 說明 |
|---------|------|------|
| `start.sh` | 4.2 KB | 互動式啟動腳本 |
| `DOCKER_SETUP.md` | 8.8 KB | 完整的 Docker 部署指南 |
| `DOCKER_QUICKSTART.md` | 3.6 KB | 快速開始指南 |
| `DOCKER_FILES_SUMMARY.md` | 本檔案 | 配置檔案總結 |

## 🏗️ 架構說明

### Dockerfile

基於官方 `redmine:5.1` 映像，包含以下功能：

```
redmine:5.1 (基礎映像)
    ↓
安裝必要工具 (git)
    ↓
複製 Plugin 檔案到 /usr/src/redmine/plugins/pervoka_achievement
    ↓
安裝依賴套件 (bundle install)
    ↓
建立自訂啟動腳本 (執行資料庫遷移)
    ↓
設定健康檢查
    ↓
啟動 Redmine (rails server)
```

### docker-compose.yml

定義兩個服務：

```yaml
services:
  postgres (資料庫)
    - 映像: postgres:15-alpine
    - 埠號: 5432 (內部)
    - 卷: postgres_data
    
  redmine (應用程式)
    - 建置自: ./Dockerfile
    - 埠號: 3000:3000
    - 依賴: postgres
    - 卷: redmine_files, redmine_plugins, redmine_themes
```

### 網路架構

```
[使用者] --> [localhost:3000]
                    ↓
            [redmine 容器]
                    ↓
            [postgres 容器]
                    ↓
           [postgres_data 卷]
```

## 🔑 關鍵特性

### 1. 自動資料庫遷移

Dockerfile 中包含的啟動腳本會自動執行：
- ✅ 等待 PostgreSQL 準備就緒
- ✅ 執行 Redmine 主資料庫遷移
- ✅ 執行 Plugin 資料庫遷移
- ✅ 載入預設資料（繁體中文）

### 2. 資料持久化

使用 Docker volumes 保存重要資料：
- `postgres_data` - 資料庫資料
- `redmine_files` - 上傳的檔案和附件
- `redmine_plugins` - Plugin 檔案
- `redmine_themes` - 主題檔案

### 3. 健康檢查

兩個容器都配置了健康檢查：

**PostgreSQL**：
```yaml
healthcheck:
  test: pg_isready -U redmine
  interval: 10s
  timeout: 5s
  retries: 5
```

**Redmine**：
```yaml
healthcheck:
  test: curl -f http://localhost:3000/
  interval: 30s
  timeout: 10s
  start_period: 60s
```

### 4. 依賴管理

`depends_on` 配置確保啟動順序：
```yaml
redmine:
  depends_on:
    postgres:
      condition: service_healthy
```

## 🚀 使用方式

### 快速啟動（推薦）

```bash
# 1. 使用啟動腳本
./start.sh

# 2. 選擇選項 6（建立並啟動 - 首次使用）
```

### 手動啟動

```bash
# 1. 建立環境變數檔案
cp .env.example .env

# 2. 建立並啟動容器
docker-compose up -d --build

# 3. 查看日誌
docker-compose logs -f redmine

# 4. 等待服務啟動（約 30-60 秒）

# 5. 訪問 http://localhost:3000
```

## 📊 資源需求

### 最低需求
- CPU: 1 核心
- 記憶體: 1 GB
- 磁碟空間: 2 GB

### 建議配置
- CPU: 2 核心
- 記憶體: 2 GB
- 磁碟空間: 5 GB

### 容器資源使用（參考）

| 容器 | CPU | 記憶體 | 磁碟 |
|------|-----|--------|------|
| postgres | 5-10% | 50-100 MB | 200 MB |
| redmine | 10-20% | 300-500 MB | 1 GB |

## 🔐 安全性考量

### 已實施的安全措施

1. ✅ 使用非 root 使用者執行容器（redmine 使用者）
2. ✅ 資料庫密碼可透過環境變數配置
3. ✅ 使用官方維護的基礎映像
4. ✅ 最小化映像大小（使用 Alpine Linux）

### 建議的額外措施

對於生產環境，建議：

1. **更改所有預設密碼**
   ```bash
   # 在 .env 檔案中設定強密碼
   POSTGRES_PASSWORD=your_strong_password
   REDMINE_SECRET_KEY_BASE=your_secret_key
   ```

2. **使用 HTTPS**
   - 配置反向代理（Nginx/Traefik）
   - 安裝 SSL 憑證

3. **限制網路存取**
   ```yaml
   networks:
     redmine_network:
       internal: true  # 內部網路
   ```

4. **定期備份**
   - 設定自動備份腳本
   - 測試還原流程

5. **更新和監控**
   - 定期更新映像
   - 監控容器日誌

## 📋 環境變數說明

### 必須設定的變數

| 變數 | 預設值 | 說明 |
|------|-------|------|
| `POSTGRES_DB` | redmine | PostgreSQL 資料庫名稱 |
| `POSTGRES_USER` | redmine | PostgreSQL 使用者 |
| `POSTGRES_PASSWORD` | redmine_password | PostgreSQL 密碼 |
| `REDMINE_SECRET_KEY_BASE` | (請設定) | Rails 應用程式密鑰 |

### 可選的變數

| 變數 | 預設值 | 說明 |
|------|-------|------|
| `REDMINE_LANG` | zh-TW | 預設語言 |
| `REDMINE_PORT` | 3000 | 外部存取埠號 |

## 🧪 測試指令

### 驗證 Plugin 安裝

```bash
# 進入容器
docker-compose exec redmine bash

# 檢查 plugin 目錄
ls -la plugins/pervoka_achievement/

# 檢查 plugin 是否已註冊
bundle exec rails runner "puts Redmine::Plugin.all.map(&:id)"
```

### 執行測試套件

```bash
# 準備測試環境
docker-compose exec redmine bundle exec rake db:test:prepare

# 執行 plugin 測試
docker-compose exec redmine bundle exec rake redmine:plugins:test NAME=pervoka_achievement
```

### 手動執行遷移

```bash
docker-compose exec redmine bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

## 🔄 更新流程

### 更新 Plugin

```bash
# 1. 停止服務
docker-compose down

# 2. 更新程式碼
git pull origin develop

# 3. 重新建立映像
docker-compose build --no-cache redmine

# 4. 啟動服務
docker-compose up -d

# 5. 執行新的遷移（如有）
docker-compose exec redmine bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

### 更新 Redmine 版本

修改 `Dockerfile` 第一行：
```dockerfile
FROM redmine:5.2  # 更新為新版本
```

然後重新建立：
```bash
docker-compose build --no-cache
docker-compose up -d
```

## 📁 檔案結構

```
PervokaAchievement/
├── Dockerfile                 # 容器映像定義
├── docker-compose.yml         # 編排配置
├── .dockerignore             # 建置忽略清單
├── .env.example              # 環境變數範本
├── start.sh                  # 啟動腳本
├── DOCKER_SETUP.md           # 完整指南
├── DOCKER_QUICKSTART.md      # 快速開始
├── DOCKER_FILES_SUMMARY.md   # 本檔案
└── [其他 plugin 檔案]
```

## 🐛 常見問題

### Q: 為什麼選擇 PostgreSQL 而非 MySQL？

A: PostgreSQL 是 Redmine 官方推薦的資料庫，具有：
- 更好的並行處理能力
- 更強的資料完整性
- 更佳的效能表現

### Q: 可以使用 SQLite 嗎？

A: 不建議在生產環境使用 SQLite。但如果只是測試，可以移除 PostgreSQL 服務並修改環境變數。

### Q: 如何查看容器內的檔案？

A: 使用以下指令：
```bash
docker-compose exec redmine bash
cd plugins/pervoka_achievement
ls -la
```

### Q: 資料存放在哪裡？

A: 使用 Docker volumes 存放：
```bash
# 查看所有 volumes
docker volume ls | grep pervoka

# 檢查 volume 詳細資訊
docker volume inspect pervoka-achievement_postgres_data
```

## 📚 相關資源

- [Docker 官方文件](https://docs.docker.com/)
- [Docker Compose 文件](https://docs.docker.com/compose/)
- [Redmine 官方文件](https://www.redmine.org/guide)
- [PostgreSQL 文件](https://www.postgresql.org/docs/)
- [Dockerfile 最佳實踐](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## 📝 版本資訊

| 元件 | 版本 |
|------|------|
| Redmine | 5.1 |
| PostgreSQL | 15 (Alpine) |
| Ruby | 3.1+ (包含在 redmine:5.1) |
| Rails | 6.1+ (包含在 redmine:5.1) |

## 🎯 下一步

1. ✅ 啟動 Docker 容器
2. ✅ 訪問 http://localhost:3000
3. ✅ 使用 admin/admin 登入
4. ✅ 更改管理員密碼
5. ✅ 建立測試專案
6. ✅ 建立測試議題
7. ✅ 查看成就系統

---

**建立時間**：2026-02-09 14:27 CST  
**專案**：PervokaAchievement  
**版本**：0.0.2  
**Docker 映像**：redmine:5.1 + pervoka_achievement plugin
