class RequestToken < Token
  
  def authorize!(options={})
    return false if authorized?
    self.user = User.find(:email => options[:email])
    self.update_attributes(:authorized_at => Time.now)
  end
  
  def exchange!
    return false unless authorized?

    RequestToken.transaction do
      access_token = AccessToken.create(:client_application => client_application)
      invalidate!
      access_token
    end
  end
  
  def request_token?; true; end
  
end