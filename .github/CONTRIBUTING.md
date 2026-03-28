# 貢獻指南

感謝您考慮為 PervokaAchievement 做出貢獻！

## 📋 目錄

- [行為準則](#行為準則)
- [如何貢獻](#如何貢獻)
- [開發流程](#開發流程)
- [程式碼風格](#程式碼風格)
- [測試要求](#測試要求)
- [提交訊息規範](#提交訊息規範)

## 行為準則

本專案採用 [Contributor Covenant](https://www.contributor-covenant.org/) 行為準則。
參與本專案即表示您同意遵守其條款。

## 如何貢獻

### 回報 Bug

在提交 Bug 報告之前，請：

1. 檢查 [現有的議題](https://github.com/bonau/PervokaAchievement/issues) 確保問題尚未被回報
2. 使用 Bug Report 範本提交詳細資訊
3. 包含重現步驟、環境資訊和錯誤訊息

### 建議新功能

1. 先檢查 [現有的功能請求](https://github.com/bonau/PervokaAchievement/issues?q=label%3Aenhancement)
2. 使用 Feature Request 範本描述您的想法
3. 說明為什麼這個功能有用
4. 如果可能，提供實作建議

### 提交程式碼

1. Fork 這個專案
2. 從 `develop` 建立您的功能分支 (`git checkout develop && git checkout -b feature/amazing-feature`)
3. 撰寫測試並確保所有測試通過
4. 遵循程式碼風格指南
5. 提交您的變更 (`git commit -m 'Add some amazing feature'`)
6. 推送到分支 (`git push origin feature/amazing-feature`)
7. 開啟一個 **以 `develop` 為 base** 的 Pull Request

## 開發流程

### 環境設定

#### 使用 Docker（推薦）

```bash
# 啟動開發環境
docker-compose up -d

# 進入容器
docker-compose exec redmine bash

# 執行測試
cd plugins/pervoka_achievement
bundle exec rspec spec
```

#### 本地開發

```bash
# 1. 安裝 Redmine
git clone https://github.com/redmine/redmine.git
cd redmine
bundle install

# 2. 複製 plugin
cd plugins
git clone https://github.com/bonau/PervokaAchievement.git pervoka_achievement

# 3. 安裝依賴
cd ..
bundle install

# 4. 執行遷移
bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement

# 5. 執行測試
cd plugins/pervoka_achievement
bundle exec rspec spec
```

### 執行測試

```bash
# 執行所有測試
bundle exec rspec spec

# 執行特定檔案
bundle exec rspec spec/models/achievement_spec.rb

# 產生覆蓋率報告
bundle exec rspec spec --format documentation
```

## 程式碼風格

### Ruby 風格指南

我們遵循 [Ruby Style Guide](https://rubystyle.guide/)。

主要規則：

- 使用 2 空格縮排
- 單引號優於雙引號（除非需要插值）
- 行長度限制 120 字元
- 方法長度不超過 20 行

### 檢查程式碼風格

```bash
# 安裝 RuboCop
gem install rubocop rubocop-rails rubocop-rspec

# 檢查程式碼
rubocop

# 自動修正
rubocop -a
```

## 測試要求

### 測試覆蓋率

- 所有新功能都必須包含測試
- 目標測試覆蓋率：> 80%
- Bug 修復應包含回歸測試

### RSpec 指南

```ruby
# 好的範例
RSpec.describe Achievement do
  describe '.check_conditions_for' do
    context 'when condition is met' do
      it 'awards the achievement' do
        expect {
          described_class.check_conditions_for(user) { true }
        }.to change { user.achievements.count }.by(1)
      end
    end
  end
end

# 使用 let 取代實例變數
let(:user) { User.find(2) }

# 使用 described_class
described_class.new(user: user)
```

## 提交訊息規範

我們遵循 [Conventional Commits](https://www.conventionalcommits.org/) 規範。

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 新功能
- `fix`: Bug 修復
- `docs`: 文件變更
- `style`: 程式碼格式調整
- `refactor`: 重構
- `test`: 測試相關
- `chore`: 建置或輔助工具變更

### 範例

```bash
feat(achievement): add new badge system

- Implement badge rendering
- Add badge icons
- Update achievement model

Closes #123
```

## Pull Request 流程

1. **更新您的分支**
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout your-branch
   git rebase develop
   ```

2. **確保測試通過**
   ```bash
   bundle exec rspec spec
   rubocop
   ```

3. **撰寫清晰的 PR 描述**
   - 使用 PR 範本
   - 說明變更的內容和原因
   - 列出相關的議題

4. **等待審查**
   - 維護者會審查您的 PR
   - 根據回饋進行調整
   - 保持分支更新

5. **合併**
   - PR 被批准後會被合併
   - 您的貢獻會被加入到專案中

## 版本發布

版本號遵循 [Semantic Versioning](https://semver.org/)：

- MAJOR：不相容的 API 變更
- MINOR：向後相容的新功能
- PATCH：向後相容的 Bug 修復

## 需要幫助？

- 📚 閱讀 [README](../README.md)
- 🐳 查看 [Docker 指南](../DOCKER_QUICKSTART.md)
- 💬 加入 [Discussions](https://github.com/bonau/PervokaAchievement/discussions)
- 📧 聯絡維護者

## 授權

提交程式碼即表示您同意在與本專案相同的授權條款下授權您的貢獻。

---

再次感謝您的貢獻！ 🎉
