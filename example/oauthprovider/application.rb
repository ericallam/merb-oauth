class Foo < Merb::Controller
  
  before :require_signed_request, :only => [:request_token]
  before :require_request_token, :only => [:access_token]
  before :require_access_token, :only => [:contact_list]

  # POST /foo/request_token
  def request_token
    
    @token = current_application.create_request_token

    if @token
      render @token.to_query, :layout => false
    else
      render "", :status => 401
    end
    
  end 
  
  # POST /foo/access_token
  def access_token
    @token = current_token.exchange!
    
    if @token
      render @token.to_query, :layout => false
    else
      render "", :status => 401
    end
  end
  
  # POST /foo/authorize
  def authorize
    @token = RequestToken.find_by_token(params[:oauth_token])
    
    @token.authorize!
          
    redirect (params[:oauth_callback] || @token.application.callback_url) + "?oauth_token=#{@token.token}"
  end
  
  # POST /foo/revoke
  def revoke
    if @token = Token.find_by_token(params[:token])
      @token.invalidate!
      render "", :status => 200
    else
      render "", :status => 404
    end
  end
  
  def contact_list
    render "private users contact lis" 
  end
  
  protected
  
  # Called from merb-oauth OAuthMixin
  def find_application_by_key(key)
    ClientApplication.find_by_key(key)
  end
  
  # Called from merb-oauth OAuthMixin
  def find_token(token)
    Token.find_by_token(token)
  end
  
end