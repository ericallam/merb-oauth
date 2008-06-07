# Move this to application.rb if you want it to be reloadable in dev mode.
Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'foo', :action =>'index')
  r.default_routes
end


Merb::Config.use { |c|
  c[:environment]         = 'production',
  c[:framework]           = {},
  c[:log_level]           = 'debug',
  c[:use_mutex]           = false,
  c[:session_store]       = 'cookie',
  c[:session_id_key]      = '_session_id',
  c[:session_secret_key]  = '7a048af8381e8a6d689b1b5070f497e5d35ed443',
  c[:exception_details]   = true,
  c[:reload_classes]      = true,
  c[:reload_time]         = 0.5
}

require File.expand_path(File.dirname(__FILE__)) + '/../../../init'

Merb.push_path(:model, Merb.root / "models") # uses **/*.rb as path glob.

use_orm :datamapper

dependency "dm-validations"
