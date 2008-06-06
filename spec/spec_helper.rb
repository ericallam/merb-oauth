require 'rubygems'
$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'merb-core'
require 'merb_oauth/merb_request'
require 'merb_oauth/oauth_mixin'
require 'logger'
require 'net/http'

Spec::Runner.configure do |config|
  config.include(Merb::Test::ControllerHelper)
  
  config.mock_with :mocha
end

Merb::Controller.send :include, OAuthMixin

Merb::Config.use { |c|
  c[:framework]           = {},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}

def (logger = Logger.new(STDOUT)).flush; end

Merb.logger = logger