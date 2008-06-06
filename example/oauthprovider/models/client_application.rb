class ClientApplication < ActiveRecord::Base
  has_many :tokens
  
  before_validation_on_create :generate_keys
  
  def server
    @oauth_server ||= OAuth::Server.new "http://your.site"
  end
  
  protected
  
  def generate_keys
    @oauth_client = oauth_server.generate_consumer_credentials
    self.key = @oauth_client.key
    self.secret = @oauth_client.secret
  end
  
end
