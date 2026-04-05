require File.expand_path('../../spec_helper', __FILE__)

RSpec.describe PervokaAchievement::Hooks::ViewsUsersHook do
  let(:hook) { described_class.instance }

  describe 'stylesheet injection' do
    it 'responds to view_layouts_base_html_head to inject CSS globally' do
      # The profile widget renders on "My account" page which does NOT load
      # the plugin stylesheet via content_for :header_tags. Without a head
      # hook the .achievement_profile_* styles are never applied.
      expect(hook).to respond_to(:view_layouts_base_html_head)
    end
  end
end
