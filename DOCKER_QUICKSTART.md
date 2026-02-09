# Docker 快速開始指南

## 🚀 三步驟啟動 Redmine + PervokaAchievement

### 步驟 1：安裝 Docker

#### Windows 或 Mac
下載並安裝 [Docker Desktop](https://www.docker.com/products/docker-desktop)

#### Linux (Ubuntu/Debian)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### WSL2 (Windows Subsystem for Linux)
在 Docker Desktop 中啟用 WSL2 整合：
1. 開啟 Docker Desktop
2. 前往 Settings → Resources → WSL Integration
3. 啟用您的 WSL2 發行版

### 步驟 2：建立環境變數檔案

```bash
# 複製範例檔案
cp .env.example .env

# （可選）編輯 .env 檔案修改密碼
nano .env
```

### 步驟 3：啟動服務

#### 方法 A：使用啟動腳本（推薦）

```bash
# 賦予執行權限
chmod +x start.sh

# 執行腳本
./start.sh

# 選擇選項 6（建立並啟動 - 首次使用）
```

#### 方法 B：直接使用 Docker Compose

```bash
# 建立並啟動所有服務
docker-compose up -d --build

# 等待約 30-60 秒讓服務完全啟動

# 查看日誌確認啟動成功
docker-compose logs -f redmine
```

### 步驟 4：訪問 Redmine

1. 開啟瀏覽器訪問：http://localhost:3000
2. 使用預設帳號登入：
   - **使用者名稱**：`admin`
   - **密碼**：`admin`
3. ⚠️ **立即更改預設密碼！**

### 步驟 5：查看成就系統

1. 登入後，點選右上角的使用者選單
2. 選擇 "**Achievements**"（成就）
3. 您將看到所有可用的成就清單

## 📋 常用指令速查

```bash
# 啟動服務
docker-compose up -d

# 停止服務
docker-compose down

# 查看日誌
docker-compose logs -f

# 重新啟動
docker-compose restart

# 進入容器
docker-compose exec redmine bash

# 執行測試
docker-compose exec redmine bundle exec rake redmine:plugins:test NAME=pervoka_achievement
```

## 🎯 可用的成就

安裝後，以下成就將可用：

1. **First Love**（初戀）
   - 條件：首次被指派議題
   - 觸發：當使用者被指派到任何議題時

2. **Attach A Picture**（附加圖片）
   - 條件：上傳圖片到專案
   - 觸發：當使用者上傳圖片類型的附件時

3. **Close Project**（關閉專案）
   - 條件：關閉一個專案
   - 觸發：當使用者關閉專案時

4. **It Must Be Kidding**（開玩笑吧）
   - 條件：重新開啟已關閉的專案
   - 觸發：當使用者重新開啟專案時

## 🔧 疑難排解

### 問題：埠號 3000 已被佔用

編輯 `docker-compose.yml`，修改埠號對應：

```yaml
ports:
  - "8080:3000"  # 將外部埠改為 8080
```

然後訪問 http://localhost:8080

### 問題：容器啟動失敗

```bash
# 查看詳細日誌
docker-compose logs

# 確認所有容器狀態
docker-compose ps

# 重新建立容器
docker-compose down
docker-compose up -d --build
```

### 問題：資料庫連線失敗

```bash
# 檢查 PostgreSQL 容器
docker-compose ps postgres

# 檢查 PostgreSQL 日誌
docker-compose logs postgres

# 重新啟動資料庫
docker-compose restart postgres
```

### 問題：Plugin 未顯示

```bash
# 進入容器
docker-compose exec redmine bash

# 手動執行遷移
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production

# 重新啟動 Redmine
exit
docker-compose restart redmine
```

## 📚 更多資訊

詳細的 Docker 部署說明請參考：[DOCKER_SETUP.md](DOCKER_SETUP.md)

## 🆘 需要幫助？

- 查看 [DOCKER_SETUP.md](DOCKER_SETUP.md) 獲取完整文件
- 查看 [README.md](README.md) 了解 Plugin 功能
- 訪問 [Redmine 官方文件](https://www.redmine.org/guide)

---

建立日期：2026-02-09
