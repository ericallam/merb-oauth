class User
  include DataMapper::Resource
  
  property :id, Integer, :serial => true
  property :email, String, :length => 50
  
  has n, :client_applications
  
  validates_present :email
end