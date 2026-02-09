# Docker 部署指南

本文件說明如何使用 Docker 執行包含 PervokaAchievement plugin 的 Redmine。

## 📋 前置需求

- Docker 20.10 或更新版本
- Docker Compose 2.0 或更新版本
- 至少 2GB 可用記憶體
- 至少 5GB 可用磁碟空間

## 🚀 快速開始

### 1. 建立並啟動容器

```bash
# 在專案根目錄執行
docker-compose up -d
```

這將會：
- 建立 PostgreSQL 資料庫容器
- 建立包含 PervokaAchievement plugin 的 Redmine 容器
- 執行資料庫遷移
- 載入預設資料

### 2. 等待服務啟動

```bash
# 查看啟動日誌
docker-compose logs -f redmine

# 等待看到類似以下訊息：
# "Listening on http://0.0.0.0:3000"
```

### 3. 訪問 Redmine

在瀏覽器開啟：http://localhost:3000

預設管理員帳號：
- **使用者名稱**：`admin`
- **密碼**：`admin`

⚠️ **重要**：首次登入後請立即更改管理員密碼！

### 4. 檢查 Plugin 安裝狀態

登入後，前往：
- **管理** → **外掛程式**
- 確認 "Pervoka Achievement plugin" 出現在清單中

查看成就系統：
- 點選右上角使用者選單
- 選擇 "Achievements"（成就）

## 📦 Docker 映像說明

### 基礎映像
- `redmine:5.1` - 官方 Redmine 5.1 映像
- `postgres:15-alpine` - PostgreSQL 15 資料庫

### 包含的功能
- ✅ Redmine 5.1
- ✅ PervokaAchievement Plugin
- ✅ PostgreSQL 15 資料庫
- ✅ 自動資料庫遷移
- ✅ 預設資料載入（繁體中文）
- ✅ 健康檢查
- ✅ 資料持久化

## 🔧 常用指令

### 容器管理

```bash
# 啟動服務
docker-compose up -d

# 停止服務
docker-compose down

# 重新啟動服務
docker-compose restart

# 查看執行狀態
docker-compose ps

# 查看日誌
docker-compose logs -f

# 只查看 Redmine 日誌
docker-compose logs -f redmine

# 只查看資料庫日誌
docker-compose logs -f postgres
```

### 進入容器

```bash
# 進入 Redmine 容器
docker-compose exec redmine bash

# 進入 PostgreSQL 容器
docker-compose exec postgres psql -U redmine -d redmine
```

### 執行 Rails 指令

```bash
# 進入 Redmine 容器後執行
docker-compose exec redmine bash

# Rails console
bundle exec rails console

# 執行 rake 任務
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

### 執行測試

```bash
# 進入容器
docker-compose exec redmine bash

# 執行所有測試
bundle exec rake redmine:plugins:test NAME=pervoka_achievement

# 執行特定測試
bundle exec ruby -I"lib:test" plugins/pervoka_achievement/test/unit/achievement_test.rb
```

## 🗄️ 資料管理

### 資料備份

```bash
# 備份資料庫
docker-compose exec postgres pg_dump -U redmine redmine > backup_$(date +%Y%m%d_%H%M%S).sql

# 備份上傳的檔案
docker run --rm -v pervoka-achievement_redmine_files:/data -v $(pwd):/backup alpine \
  tar czf /backup/files_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 資料還原

```bash
# 還原資料庫
cat backup_20260209_142000.sql | docker-compose exec -T postgres psql -U redmine -d redmine

# 還原檔案
docker run --rm -v pervoka-achievement_redmine_files:/data -v $(pwd):/backup alpine \
  tar xzf /backup/files_backup_20260209_142000.tar.gz -C /data
```

### 清除所有資料

⚠️ **警告**：此操作會刪除所有資料，包括資料庫和上傳的檔案！

```bash
# 停止並刪除容器和卷
docker-compose down -v

# 刪除映像（可選）
docker rmi pervoka-achievement-redmine
```

## 🔐 安全性建議

### 生產環境部署

1. **更改密鑰**

建立 `.env` 檔案（從 `.env.example` 複製）：

```bash
cp .env.example .env
```

生成新的密鑰：

```bash
docker run --rm redmine:5.1 bundle exec rake secret
```

將生成的密鑰填入 `.env` 檔案的 `REDMINE_SECRET_KEY_BASE`。

2. **更改資料庫密碼**

在 `.env` 檔案中修改：
```env
POSTGRES_PASSWORD=your_strong_password_here
```

3. **使用反向代理**

建議使用 Nginx 或 Traefik 作為反向代理，並啟用 HTTPS。

範例 Nginx 配置：

```nginx
server {
    listen 80;
    server_name redmine.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name redmine.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

4. **定期備份**

設定 cron job 定期備份資料：

```bash
# 每天凌晨 2 點備份
0 2 * * * /path/to/backup_script.sh
```

5. **限制容器權限**

在 `docker-compose.yml` 中添加：

```yaml
security_opt:
  - no-new-privileges:true
read_only: true
tmpfs:
  - /tmp
```

## 🐛 疑難排解

### 問題：容器無法啟動

**檢查日誌**：
```bash
docker-compose logs redmine
docker-compose logs postgres
```

**常見原因**：
- 資料庫尚未準備好：等待幾秒後重試
- 埠號被佔用：修改 `.env` 中的 `REDMINE_PORT`
- 記憶體不足：增加 Docker 可用記憶體

### 問題：Plugin 未顯示

**檢查 plugin 是否正確安裝**：
```bash
docker-compose exec redmine ls -la plugins/pervoka_achievement
```

**手動執行遷移**：
```bash
docker-compose exec redmine bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

**重新啟動容器**：
```bash
docker-compose restart redmine
```

### 問題：無法連線到資料庫

**檢查資料庫狀態**：
```bash
docker-compose ps postgres
docker-compose exec postgres pg_isready -U redmine
```

**檢查網路連線**：
```bash
docker-compose exec redmine ping postgres
```

### 問題：效能緩慢

**增加資源限制**：

在 `docker-compose.yml` 中添加：

```yaml
services:
  redmine:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

**啟用快取**：
參考 Redmine 官方文件配置 memcached 或 Redis。

## 📊 監控與日誌

### 查看容器狀態

```bash
# 檢查健康狀態
docker-compose ps

# 查看資源使用
docker stats
```

### 日誌管理

```bash
# 查看最近 100 行日誌
docker-compose logs --tail=100 redmine

# 持續追蹤日誌
docker-compose logs -f redmine

# 儲存日誌到檔案
docker-compose logs redmine > redmine.log
```

## 🔄 更新與維護

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

# 5. 執行遷移
docker-compose exec redmine bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production
```

### 更新 Redmine

修改 `Dockerfile` 中的基礎映像版本：

```dockerfile
FROM redmine:5.2  # 更新版本號
```

然後執行：

```bash
docker-compose build --no-cache
docker-compose up -d
```

## 📝 開發模式

### 啟用即時程式碼更新

在 `docker-compose.yml` 中取消註解：

```yaml
volumes:
  - ./:/usr/src/redmine/plugins/pervoka_achievement
```

### 執行測試環境

```bash
# 建立測試資料庫
docker-compose exec redmine bundle exec rake db:create RAILS_ENV=test

# 執行遷移
docker-compose exec redmine bundle exec rake db:migrate RAILS_ENV=test
docker-compose exec redmine bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=test

# 執行測試
docker-compose exec redmine bundle exec rake redmine:plugins:test NAME=pervoka_achievement
```

## 🌐 環境變數參考

| 變數名稱 | 預設值 | 說明 |
|---------|-------|------|
| `POSTGRES_DB` | redmine | PostgreSQL 資料庫名稱 |
| `POSTGRES_USER` | redmine | PostgreSQL 使用者名稱 |
| `POSTGRES_PASSWORD` | redmine_password | PostgreSQL 密碼 |
| `REDMINE_LANG` | zh-TW | Redmine 預設語言 |
| `REDMINE_SECRET_KEY_BASE` | (必須設定) | Rails 密鑰 |
| `REDMINE_PORT` | 3000 | Redmine 服務埠號 |

## 📚 相關資源

- [Redmine 官方文件](https://www.redmine.org/projects/redmine/wiki/Guide)
- [Docker 官方文件](https://docs.docker.com/)
- [PostgreSQL 文件](https://www.postgresql.org/docs/)
- [PervokaAchievement GitHub](https://github.com/bonau/PervokaAchievement)

## 💡 提示與技巧

1. **使用 docker-compose 別名**：
   ```bash
   alias dc='docker-compose'
   dc up -d
   dc logs -f
   ```

2. **快速重新載入 Redmine**：
   ```bash
   docker-compose exec redmine touch tmp/restart.txt
   ```

3. **清理未使用的資源**：
   ```bash
   docker system prune -a --volumes
   ```

## 🤝 支援與貢獻

如有問題或建議，請：
- 開啟 GitHub Issue
- 提交 Pull Request
- 聯絡維護者

---

**建立日期**：2026-02-09  
**專案**：PervokaAchievement  
**版本**：0.0.2
