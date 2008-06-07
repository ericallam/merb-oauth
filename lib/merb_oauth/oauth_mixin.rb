require 'oauth/signature'

module OAuthMixin
  
  protected
  
  # ==== Before Filters
  # Use these methods as before filters in your controllers
  
  # Use this method to protect private resources.
  # The Consumer must have received authorization from the
  # End User and retrieved the AccessToken.
  def require_access_token
    # make sure the request has been signed correctly
    verify_signature
  
    # NOTE make sure you define Controller#find_token which
    # returns an object that responds to the access_token? message
    # access_token? should return true if the token object is an AccessToken
    # it should return false if the token object is a RequestToken
    if !current_token.access_token?
      throw :halt, render(invalid_access_token_message, :status => 401, :layout => false)
    end
  end
  
  def require_request_token
    # make sure the request has been signed correctly
    verify_signature
    
    
    # NOTE make sure you define Controller#find_token which
    # returns an object that responds to the request_token? message
    # request_token? should return true if the token object is a RequestToken
    # it should return false if the token object is a AccessToken
    if !current_token.request_token?
      throw :halt, render(invalid_request_token_message, :status => 401, :layout => false)
    end
  end
  
  def require_signed_request
    # make sure the request has been signed correctly
    # this method will set self.current_token
    # if the request cannot be verified, verify_signature
    # will throw :halt and exit the request
    verify_signature
  end
  
  def current_token=(new_token)
    return if new_token.nil?
    @current_token = new_token
  end
  
  def current_application
    @current_application ||= current_token.application
  end
  
  def current_application=(new_current_application)
    return if new_current_application.nil?
    @current_application = new_current_application
  end
  
  def current_token
    @current_token
  end
  
  # You must implement this method in your controller
  # ==== Return
  #  <Object>:: must respond_to:
  #   #application => <Object> must respond_to #secret
  #   #secret => <String>
  #   #access_token? => <Boolean>
  #   #request_token? => <Boolean>
  def find_token(token_string)
    raise NotImplementedError
  end
  
  # You must implement this method in your controller
  # ==== Return
  #  <Object>:: must respond_to:
  #   #secret => <String>
  def find_application_by_key(consumer_key)
    raise NotImplementedError
  end
  
  # You can implement this in your controller
  # Used for 'Remembering' the request, such as creating a Nonce object
  # that holds the request nonce and request timestamp.
  #
  # This is called in each before filter, only if the signature
  # has been verified.  If you wanted to guard against Reply attacks
  # You would define remember request to something like this: (Uses ActiveRecord)
  #
  #   def remember_request(signature)
  #     if Nonce.find_by_nonce_and_timestamp(signature.request.nonce, signature.request.timestamp)
  #       throw :halt, render("Reply attack.  That request has already been performed.", :status => 401, :layout => false)
  #     else
  #        Nonce.create(:nonce => signature.request.nonce, :timestamp => signature.request.timestamp)
  #     end
  #   end
  #
  # See http://oauth.net/core/1.0/#nonce for more information
  def remember_request(signature)
    # implement in your controller
  end
   
  private
  
  # Verifies the Request signature.
  # Will attempt to retrieve the Consumer application by the consumer key
  # Will attempt to retrieve either a RequestToken or AccessToken
  # Make sure you define #find_application_by_key and #find_token (see above more more deets)
  #
  # Will throw an 401 response if the signature does not verify.  
  #
  # See http://oauth.net/core/1.0/#signing_process for information about OAuth request signing
  def verify_signature
    signature = OAuth::Signature.build(request) do |token, consumer_key|
      self.current_application = find_application_by_key(consumer_key)
      self.current_token = find_token(token)

      token_secret  = self.current_token ? self.current_token.secret : nil
      app_secret    = self.current_application ? self.current_application.secret : nil
      
      [token_secret, app_secret]
    end
    
    if signature.verify
      remember_request(signature)
    else
      throw :halt, render("Invalid OAuth Request.  Signature could not be verified.", :status => 401, :layout => false)
    end
  end
  
  # Message used when Consumer requests an OAuth protected resource
  # With a RequestToken instead of the required AccessToken
  # Overwrite in your controller to customize
  def invalid_access_token_message
    "Illegal Attempt to access private resource with a RequestToken.  Please obtain an AccessToken before proceeding."
  end
  
  # Message used when Consumer attempts to exchange RequestToken for an AccessToken
  # with a token that is not a Request Token.  
  # Overwrite in your controller to customize
  def invalid_request_token_message
    "Illegal Attempt to retrieve AccessToken."
  end
  
end