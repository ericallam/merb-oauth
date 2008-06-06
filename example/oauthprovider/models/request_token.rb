class RequestToken < Token
  
  def authorize!(options={})
    return false if authorized?
    
    self.update_attribute(:authorized_at, Time.now)
  end
  
  def exchange!
    return false unless authorized?

    RequestToken.transaction do
      access_token = AccessToken.create(:application => application)
      invalidate!
      access_token
    end
  end
  
  def request_token?; true; end
  
end