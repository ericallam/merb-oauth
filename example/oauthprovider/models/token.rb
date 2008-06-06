class Token < ActiveRecord::Base
  belongs_to :application, :class_name => "ClientApplication", :foreign_key => "client_application_id"
  
  validates_uniqueness_of :token
  validates_presence_of :application, :token, :secret
  
  before_validation_on_create :generate_keys
  
  def invalidated?
    invalidated_at != nil
  end
  
  def invalidate!
    update_attribute(:invalidated_at, Time.now)
  end
  
  def authorized?
    authorized_at != nil && !invalidated?
  end
  
  def to_query
    "oauth_token=#{escape(token)}&oauth_token_secret=#{escape(secret)}"
  end
    
  protected
  
  def escape(value)
    CGI.escape(value.to_s).gsub("%7E", '~').gsub("+", "%20")
  end
  
  def generate_keys
    @oauth_token = application.oauth_server.generate_credentials
    self.token = @oauth_token.first
    self.secret = @oauth_token[1]
  end
  
end