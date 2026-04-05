# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'achievements', :to => 'achievements#index'

scope '/admin' do
  get   'achievements',             :to => 'admin_achievements#index',       :as => 'admin_achievements'
  patch 'achievements/bulk_update', :to => 'admin_achievements#bulk_update', :as => 'bulk_update_admin_achievements'
end
