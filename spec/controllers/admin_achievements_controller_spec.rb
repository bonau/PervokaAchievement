require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe AdminAchievementsController, type: :controller do
  fixtures :users

  let(:admin) { User.find(1) }
  let(:non_admin) { User.find(2) }

  after { AchievementSetting.delete_all }

  describe 'GET #index' do
    context 'as admin' do
      before do
        request.session[:user_id] = admin.id
        User.current = admin
      end

      after { User.current = nil }

      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns @achievement_classes' do
        get :index
        expect(assigns(:achievement_classes)).to be_a(Array)
        expect(assigns(:achievement_classes)).to include(CreateFirstIssueAchievement)
      end

      it 'assigns @settings as a hash indexed by achievement_type' do
        AchievementSetting.create!(achievement_type: 'CreateFirstIssueAchievement', enabled: false)
        get :index
        settings = assigns(:settings)
        expect(settings).to be_a(Hash)
        expect(settings['CreateFirstIssueAchievement']).to be_a(AchievementSetting)
      end

      it 'uses the admin layout' do
        get :index
        expect(response).to render_template(layout: 'admin')
      end
    end

    context 'as non-admin' do
      before do
        request.session[:user_id] = non_admin.id
        User.current = non_admin
      end

      after { User.current = nil }

      it 'returns 403 forbidden' do
        get :index
        expect(response).to have_http_status(:forbidden)
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

  describe 'PATCH #bulk_update' do
    before do
      request.session[:user_id] = admin.id
      User.current = admin
    end

    after { User.current = nil }

    it 'creates new setting rows' do
      expect {
        patch :bulk_update, params: {
          settings: {
            'CreateFirstIssueAchievement' => {
              enabled: '1',
              custom_title: 'New Title',
              custom_description: '',
              custom_quote: ''
            }
          }
        }
      }.to change { AchievementSetting.count }.by(1)

      setting = AchievementSetting.find_by(achievement_type: 'CreateFirstIssueAchievement')
      expect(setting.enabled?).to be true
      expect(setting.custom_title).to eq 'New Title'
    end

    it 'updates existing setting rows' do
      AchievementSetting.create!(
        achievement_type: 'CreateFirstIssueAchievement',
        enabled: true,
        custom_title: 'Old Title'
      )

      patch :bulk_update, params: {
        settings: {
          'CreateFirstIssueAchievement' => {
            enabled: '0',
            custom_title: 'Updated Title',
            custom_description: '',
            custom_quote: ''
          }
        }
      }

      setting = AchievementSetting.find_by(achievement_type: 'CreateFirstIssueAchievement')
      expect(setting.enabled?).to be false
      expect(setting.custom_title).to eq 'Updated Title'
    end

    it 'clears custom text when blank is submitted' do
      AchievementSetting.create!(
        achievement_type: 'CreateFirstIssueAchievement',
        custom_title: 'Old Title'
      )

      patch :bulk_update, params: {
        settings: {
          'CreateFirstIssueAchievement' => {
            enabled: '1',
            custom_title: '',
            custom_description: '',
            custom_quote: ''
          }
        }
      }

      setting = AchievementSetting.find_by(achievement_type: 'CreateFirstIssueAchievement')
      expect(setting.custom_title).to be_nil
    end

    it 'redirects to index with success notice' do
      patch :bulk_update, params: {
        settings: {
          'CreateFirstIssueAchievement' => {
            enabled: '1',
            custom_title: '',
            custom_description: '',
            custom_quote: ''
          }
        }
      }

      expect(response).to redirect_to(admin_achievements_path)
      expect(flash[:notice]).to be_present
    end

    context 'as non-admin' do
      before do
        request.session[:user_id] = non_admin.id
        User.current = non_admin
      end

      it 'returns 403 forbidden' do
        patch :bulk_update, params: { settings: {} }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
