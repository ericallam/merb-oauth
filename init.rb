$: << File.expand_path(File.dirname(__FILE__)) / "lib"
require 'oauth'

require 'oauth/signature/hmac/sha1'
require 'merb_oauth/merb_request'
require 'oauth/server'
require 'merb_oauth/oauth_mixin'

Merb::Controller.send :include, OAuthMixin
