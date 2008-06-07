class Token
  include DataMapper::Resource
  
  property :id, Integer, :serial => true
  property :type, Discriminator
  property :user_id, Integer
  property :client_application_id, Integer
  property :token, String, :length => 50
  property :secret, String, :length => 50
  property :authorized_at, DateTime
  property :invalidated_at, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime
  
  belongs_to :client_application
  has 1, :user
  
  validates_is_unique :token
  validates_present :client_application_id
       
  before :save do
    credentials = client_application.server.generate_credentials
    self.token = credentials.first
    self.secret = credentials.last
  end
  
  def invalidated?
    invalidated_at != nil
  end
  
  def invalidate!
    update_attributes(:invalidated_at => Time.now)
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

  
end