# Redmine with PervokaAchievement Plugin
FROM redmine:6.1

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
RUN echo "gem 'rspec-rails', '~> 6.0', group: [:development, :test]" >> Gemfile.local && \
    echo "gem 'rspec_junit_formatter', group: [:test]" >> Gemfile.local && \
    echo "gem 'rails-controller-testing', group: [:test]" >> Gemfile.local && \
    bundle install

# 使用官方 Redmine entrypoint（自動處理 database.yml 生成與 db:migrate）
# 暴露 Redmine 預設埠
EXPOSE 3000

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1
