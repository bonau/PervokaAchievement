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
  end
end
