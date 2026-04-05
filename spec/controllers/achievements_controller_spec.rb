require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AchievementsController, type: :controller do
  fixtures :users, :projects

  let(:user) { User.find(2) }

  before do
    request.session[:user_id] = user.id
    User.current = user
  end

  after { User.current = nil }

  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @all_achievement_classes' do
      get :index
      expect(assigns(:all_achievement_classes)).to be_a(Array)
      expect(assigns(:all_achievement_classes)).to include(FirstLoveAchievement)
    end

    it 'assigns @user_achievements' do
      get :index
      expect(assigns(:user_achievements)).not_to be_nil
    end

    it 'assigns @unlocked_achievement_classes' do
      FirstLoveAchievement.create(user: user)

      get :index
      expect(assigns(:unlocked_achievement_classes)).to be_a(Array)
    end

    it 'assigns @unlockable_achievement_classes' do
      get :index
      expect(assigns(:unlockable_achievement_classes)).to be_a(Array)
    end

    it 'separates unlocked and unlockable as mutually exclusive' do
      FirstLoveAchievement.create(user: user)

      get :index
      unlocked  = assigns(:unlocked_achievement_classes)
      unlockable = assigns(:unlockable_achievement_classes)

      expect(unlocked & unlockable).to be_empty
    end

    it 'covers all registered achievements between unlocked and unlockable' do
      get :index
      all        = assigns(:all_achievement_classes)
      unlocked   = assigns(:unlocked_achievement_classes)
      unlockable = assigns(:unlockable_achievement_classes)

      expect((unlocked + unlockable).sort_by(&:name)).to eq all.sort_by(&:name)
    end

    it 'includes an awarded achievement in unlocked list' do
      FirstLoveAchievement.create(user: user)

      get :index
      expect(assigns(:unlocked_achievement_classes)).to include(FirstLoveAchievement)
    end

    it 'assigns @achievements_by_category' do
      get :index
      by_cat = assigns(:achievements_by_category)
      expect(by_cat).to be_a(Hash)
      expect(by_cat.keys).to all(be_a(Symbol))
    end

    it 'groups achievements by their category' do
      get :index
      by_cat = assigns(:achievements_by_category)
      by_cat.each do |cat, achievements|
        achievements[:unlocked].each { |a| expect(a.class.category).to eq cat }
        achievements[:unlockable].each { |a| expect(a.category).to eq cat }
      end
    end

    it 'includes all registered achievements across categories' do
      get :index
      by_cat = assigns(:achievements_by_category)
      all_in_categories = by_cat.values.flat_map { |h| h[:unlocked].map(&:class) + h[:unlockable] }.uniq
      expect(all_in_categories.sort_by(&:name)).to eq assigns(:all_achievement_classes).sort_by(&:name)
    end

    context 'when an achievement is disabled' do
      before do
        AchievementSetting.create!(achievement_type: 'FirstLoveAchievement', enabled: false)
      end

      after { AchievementSetting.delete_all }

      it 'excludes disabled achievement from @all_achievement_classes' do
        get :index
        expect(assigns(:all_achievement_classes)).not_to include(FirstLoveAchievement)
      end

      it 'excludes disabled achievement from @achievements_by_category' do
        get :index
        by_cat = assigns(:achievements_by_category)
        all_classes = by_cat.values.flat_map { |h| h[:unlocked].map(&:class) + h[:unlockable] }
        expect(all_classes).not_to include(FirstLoveAchievement)
      end
    end

    context 'when not logged in' do
      before do
        request.session[:user_id] = nil
        User.current = nil
      end

      it 'redirects to login' do
        get :index
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('/login')
      end
    end

    it 'assigns @user_setting' do
      get :index
      expect(assigns(:user_setting)).to be_a(AchievementUserSetting)
    end

    context 'permission check' do
      it 'enforces :view_achievements permission via before_action' do
        callbacks = described_class._process_action_callbacks
        filter_names = callbacks.select { |c| c.kind == :before }.map(&:filter)
        expect(filter_names).to include(:check_view_permission)
      end

      it 'denies access when permission is missing' do
        allow_any_instance_of(User).to receive(:allowed_to?)
          .with(:view_achievements, nil, global: true)
          .and_return(false)
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #show' do
    let(:other_user) { User.find(3) }

    after { AchievementUserSetting.delete_all }

    context 'viewing own profile' do
      it 'returns success' do
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns @target_user' do
        get :show, params: { id: user.id }
        expect(assigns(:target_user)).to eq user
      end
    end

    context 'viewing another user with public profile' do
      before do
        AchievementUserSetting.create!(user: other_user, public_profile: true)
      end

      it 'returns success' do
        get :show, params: { id: other_user.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns @target_user to the other user' do
        get :show, params: { id: other_user.id }
        expect(assigns(:target_user)).to eq other_user
      end
    end

    context 'viewing another user without public profile' do
      it 'denies access' do
        get :show, params: { id: other_user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as admin viewing non-public profile' do
      let(:admin) { User.find(1) }

      before do
        request.session[:user_id] = admin.id
        User.current = admin
      end

      it 'returns success' do
        get :show, params: { id: other_user.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #leaderboard' do
    before { Achievement.where(user_id: user.id).delete_all }

    it 'returns success' do
      get :leaderboard
      expect(response).to have_http_status(:success)
    end

    it 'assigns @leaderboard' do
      get :leaderboard
      expect(assigns(:leaderboard)).to be_a(Array)
    end

    it 'includes users with achievements sorted by score descending' do
      FirstLoveAchievement.create(user: user)
      get :leaderboard
      leaderboard = assigns(:leaderboard)
      expect(leaderboard).not_to be_empty
      expect(leaderboard.first[:user]).to eq user
      expect(leaderboard.first[:score]).to eq FirstLoveAchievement.effective_points
      expect(leaderboard.first[:count]).to eq 1
    end

    it 'excludes users without any achievements' do
      get :leaderboard
      leaderboard = assigns(:leaderboard)
      user_ids = leaderboard.map { |e| e[:user].id }
      expect(user_ids).not_to include(user.id)
    end
  end

  describe 'GET #index (JSON)' do
    before do
      Setting.rest_api_enabled = '1'
      @token = Token.create!(user: user, action: 'api')
    end

    after do
      @token&.destroy
      Setting.rest_api_enabled = '0'
    end

    let(:api_params) { { key: @token.value } }

    it 'returns JSON with user achievements' do
      get :index, params: api_params, format: :json
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json).to have_key('user')
      expect(json).to have_key('total_score')
      expect(json).to have_key('unlocked')
      expect(json).to have_key('locked')
    end

    it 'includes achievement details in locked list' do
      get :index, params: api_params, format: :json
      json = JSON.parse(response.body)
      locked = json['locked']
      expect(locked).to be_a(Array)
      expect(locked.first).to include('type', 'category', 'tier', 'points', 'tags')
    end

    it 'includes unlocked achievements with timestamps' do
      FirstLoveAchievement.create(user: user)
      get :index, params: api_params, format: :json
      json = JSON.parse(response.body)
      unlocked = json['unlocked']
      expect(unlocked.size).to be >= 1
      expect(unlocked.first).to include('unlocked_at', 'id')
    end
  end

  describe 'GET #show (JSON)' do
    before do
      Setting.rest_api_enabled = '1'
      @token = Token.create!(user: user, action: 'api')
    end

    after do
      @token&.destroy
      Setting.rest_api_enabled = '0'
    end

    let(:api_params) { { key: @token.value } }

    it 'returns JSON for own profile' do
      get :show, params: api_params.merge(id: user.id), format: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user']['id']).to eq(user.id)
    end

    it 'returns 403 for non-public profile' do
      other_user = User.find(3)
      get :show, params: api_params.merge(id: other_user.id), format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET #leaderboard (JSON)' do
    before do
      Setting.rest_api_enabled = '1'
      @token = Token.create!(user: user, action: 'api')
    end

    after do
      @token&.destroy
      Setting.rest_api_enabled = '0'
    end

    let(:api_params) { { key: @token.value } }

    it 'returns JSON leaderboard with ranks' do
      FirstLoveAchievement.create(user: user)
      get :leaderboard, params: api_params, format: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('leaderboard')
      expect(json['leaderboard']).to be_a(Array)
      entry = json['leaderboard'].first
      expect(entry).to include('rank', 'user', 'score', 'achievement_count')
    end
  end

  describe 'PATCH #update_visibility' do
    after { AchievementUserSetting.delete_all }

    it 'creates setting and enables public profile' do
      patch :update_visibility, params: { public_profile: '1' }
      expect(AchievementUserSetting.public_profile?(user)).to be true
    end

    it 'disables public profile' do
      AchievementUserSetting.create!(user: user, public_profile: true)
      patch :update_visibility, params: { public_profile: '0' }
      expect(AchievementUserSetting.public_profile?(user)).to be false
    end

    it 'redirects to index with success notice' do
      patch :update_visibility, params: { public_profile: '1' }
      expect(response).to redirect_to(achievements_path)
      expect(flash[:notice]).to be_present
    end
  end
end
