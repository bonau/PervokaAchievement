#!/bin/bash
# PervokaAchievement - 快速啟動腳本

set -e

echo "=========================================="
echo "  PervokaAchievement Docker 啟動腳本"
echo "=========================================="
echo ""

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 檢查 Docker 是否安裝
if ! command -v docker &> /dev/null; then
    echo -e "${RED}錯誤：未找到 Docker。請先安裝 Docker。${NC}"
    exit 1
fi

# 檢查 Docker Compose 是否安裝
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}錯誤：未找到 Docker Compose。請先安裝 Docker Compose。${NC}"
    exit 1
fi

# 檢查 .env 檔案
if [ ! -f .env ]; then
    echo -e "${YELLOW}警告：未找到 .env 檔案。${NC}"
    echo "建立 .env 檔案從 .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓ 已建立 .env 檔案${NC}"
    echo -e "${YELLOW}⚠ 生產環境請務必修改 .env 中的密碼和密鑰！${NC}"
    echo ""
fi

# 顯示選項
echo "請選擇操作："
echo "1) 啟動服務"
echo "2) 停止服務"
echo "3) 重新啟動服務"
echo "4) 查看日誌"
echo "5) 查看服務狀態"
echo "6) 建立並啟動（首次使用）"
echo "7) 完全清除（包含資料）"
echo "8) 進入 Redmine 容器"
echo "9) 執行測試"
echo "0) 離開"
echo ""

read -p "請輸入選項 [1-9, 0]: " choice

case $choice in
    1)
        echo -e "${GREEN}啟動服務...${NC}"
        docker-compose up -d
        echo ""
        echo -e "${GREEN}✓ 服務已啟動${NC}"
        echo "請訪問: http://localhost:3000"
        echo "預設帳號: admin / admin"
        ;;
    2)
        echo -e "${YELLOW}停止服務...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ 服務已停止${NC}"
        ;;
    3)
        echo -e "${YELLOW}重新啟動服務...${NC}"
        docker-compose restart
        echo -e "${GREEN}✓ 服務已重新啟動${NC}"
        ;;
    4)
        echo -e "${GREEN}顯示日誌（按 Ctrl+C 退出）...${NC}"
        docker-compose logs -f
        ;;
    5)
        echo -e "${GREEN}服務狀態：${NC}"
        docker-compose ps
        ;;
    6)
        echo -e "${GREEN}建立並啟動服務（首次使用）...${NC}"
        echo "這可能需要幾分鐘時間..."
        docker-compose up -d --build
        echo ""
        echo "等待服務啟動..."
        sleep 10
        echo ""
        echo -e "${GREEN}✓ 服務已啟動${NC}"
        echo ""
        echo "=========================================="
        echo "  🎉 Redmine 已準備就緒！"
        echo "=========================================="
        echo ""
        echo "訪問: http://localhost:3000"
        echo ""
        echo "預設管理員帳號："
        echo "  使用者名稱: admin"
        echo "  密碼: admin"
        echo ""
        echo "⚠️  請立即更改預設密碼！"
        echo ""
        echo "查看成就系統："
        echo "  登入後點選右上角使用者選單 → Achievements"
        echo ""
        ;;
    7)
        echo -e "${RED}警告：此操作將刪除所有資料！${NC}"
        read -p "確定要繼續嗎？(yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${RED}刪除所有容器和資料...${NC}"
            docker-compose down -v
            echo -e "${GREEN}✓ 已清除所有資料${NC}"
        else
            echo "操作已取消"
        fi
        ;;
    8)
        echo -e "${GREEN}進入 Redmine 容器...${NC}"
        docker-compose exec redmine bash
        ;;
    9)
        echo -e "${GREEN}執行測試...${NC}"
        echo "準備測試環境..."
        docker-compose exec redmine bash -c "
            bundle exec rake db:create RAILS_ENV=test 2>/dev/null || true
            bundle exec rake db:migrate RAILS_ENV=test
            bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=test
            echo ''
            echo '執行測試...'
            bundle exec rake redmine:plugins:test NAME=pervoka_achievement
        "
        ;;
    0)
        echo "再見！"
        exit 0
        ;;
    *)
        echo -e "${RED}無效的選項${NC}"
        exit 1
        ;;
esac

echo ""
echo "完成！"
