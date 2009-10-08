ActionController::Routing::Routes.draw do |map|
  map.resource :session, :only => [:new, :create, :destroy]
  map.resource :password, :only => [:new, :create, :edit, :update]
end