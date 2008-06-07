class ClientApplication
  include DataMapper::Resource
  
  property :id, Integer, :serial => true
  property :name, String
  property :url, String
  property :support_url, String
  property :callback_url, String
  property :consumer_key, String, :length => 50, :index => true
  property :secret, String, :length => 50
  property :created_at, DateTime
  property :updated_at, DateTime
  
  has n, :tokens
  
  before :save do
    client = server.generate_consumer_credentials
    self.consumer_key = client.key
    self.secret = client.secret
  end
  
  def server
    @oauth_server ||= OAuth::Server.new "http://your.site"
  end
  
end
