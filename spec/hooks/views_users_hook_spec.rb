require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Hooks::ViewsUsersHook do
  let(:hook) { described_class.instance }

  describe 'stylesheet injection' do
    it 'responds to view_layouts_base_html_head to inject CSS globally' do
      expect(hook).to respond_to(:view_layouts_base_html_head)
    end
  end

  describe 'permission guard' do
    it 'checks :view_achievements permission in the profile partial' do
      # If the user's role has :view_achievements revoked, the profile
      # widget should not render. The partial must contain a permission
      # guard to prevent showing achievements to unauthorised users.
      partial_path = File.expand_path('../../app/views/hooks/_user_achievements.html.erb', __dir__)
      content = File.read(partial_path)
      expect(content).to include('view_achievements'),
        'profile partial should check :view_achievements permission'
    end
  end
end
