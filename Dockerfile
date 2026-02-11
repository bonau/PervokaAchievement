# Redmine with PervokaAchievement Plugin
FROM redmine:5.1

# 維護者資訊
LABEL maintainer="PervokaAchievement"
LABEL description="Redmine with PervokaAchievement plugin installed"

# 切換到 root 使用者以安裝套件
USER root

# 安裝必要的工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# 切換回 redmine 使用者
USER redmine

# 複製 plugin 到 Redmine 的 plugins 目錄
COPY --chown=redmine:redmine . /usr/src/redmine/plugins/pervoka_achievement

# 設定工作目錄
WORKDIR /usr/src/redmine

# 安裝 RSpec 測試依賴
RUN echo -e "gem 'rspec-rails', '~> 6.0', group: [:development, :test]" >> Gemfile.local && \
    bundle install --without ""

# 建立啟動腳本來執行資料庫遷移
USER root
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 等待資料庫準備好\n\
echo "Waiting for database..."\n\
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\\q" 2>/dev/null; do\n\
  echo "Postgres is unavailable - sleeping"\n\
  sleep 2\n\
done\n\
\n\
echo "Database is up - executing migrations"\n\
\n\
# 執行 Redmine 資料庫遷移\n\
bundle exec rake db:migrate RAILS_ENV=production\n\
\n\
# 執行 plugin 資料庫遷移\n\
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement RAILS_ENV=production\n\
\n\
# 載入預設資料（僅在首次安裝時）\n\
bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=zh-TW || true\n\
\n\
# 啟動 Redmine\n\
exec "$@"\n\
' > /docker-entrypoint-custom.sh && \
    chmod +x /docker-entrypoint-custom.sh && \
    chown redmine:redmine /docker-entrypoint-custom.sh

USER redmine

# 使用自訂的 entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]

# 暴露 Redmine 預設埠
EXPOSE 3000

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1
