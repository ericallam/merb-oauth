require File.dirname(__FILE__) + '/spec_helper'
require 'oauth/consumer'

describe OAuthMixin do
  
  Merb::Router.prepare {|r| r.default_routes }
  Merb.add_mime_type(:html, :to_html, %w[text/html application/xhtml+xml application/html], :charset => "utf-8")
  class Posts < Merb::Controller
    before :require_access_token, :only => :access_token
    before :require_request_token, :only => :request_token
    before :require_signed_request, :only => :signed_request
    provides :html
    def signed_request; render "this is signed"; end
    def access_token; render "this is access"; end
    def request_token; render "this is request"; end
    def index; render "this is index"; end
    private
    def remember_request(signature)
      throw :halt, render("Replay attack", :status => 401, :layout => false) if request_already_happened?
    end
  end
  
  def get(path, options={})
    dispatch(default_env.merge("REQUEST_METHOD" => "GET", "REQUEST_URI" => path).merge(options))
  end
  
  def default_env
    @env = {
      "HTTP_HOST" => "test.host",
      "rack.input" => StringIO.new(""),
      "HTTP_ACCEPT" => "text/html"
    }
  end
  
  def dispatch(env)
    Merb::Dispatcher.handle(env)
  end
  
  describe "with no before filters" do
    it "should render" do
      controller = get "/posts"
      controller.body.should == "this is index"
    end
  end
  
  describe "require_request_token" do
    before(:each) do
      @uri = URI.parse('http://test.host/posts/request_token')
      @request = Net::HTTP::Get.new(@uri.path)
      
      @consumer = OAuth::Consumer.new('consumer_key', 'consumer_secret', :site => "http://test.host")
      @request_token = OAuth::RequestToken.new(@consumer, 'token', 'token_secret')
      
      @request_token.sign!(@request, {:nonce => 22557, :timestamp => "1199645624"})
      
      @mock_application = mock('consumer')
      @mock_application.stubs(:secret).returns('consumer_secret')
      
      @mock_request_token = mock('request_token')
      @mock_request_token.stubs(:secret).returns('token_secret')
      @mock_request_token.stubs(:request_token?).returns(true)
      
      Posts.any_instance.stubs(:find_token).with('token').returns(@mock_request_token)
      Posts.any_instance.stubs(:find_application_by_key).with('consumer_key').returns(@mock_application)
      Posts.any_instance.stubs(:request_already_happened?).returns(false)
    end
    
    describe "correctly signed" do
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should go through the before filter" do
        do_get
        @controller.body.should == "this is request"
      end
      
      it "should set the current_application" do
        do_get
        @controller.current_application.should == @mock_application
      end
      
      it "should set the current_token to nil" do
        do_get
        @controller.current_token.should == @mock_request_token
      end
    end
    
    describe "correctly signed but a replay attack (request has already been performed)" do
      
      before(:each) do
        Posts.any_instance.expects(:request_already_happened?).returns(true)
      end
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should return a 401 response" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is request"
      end
    end
    
    describe "correctly signed with with wrong token type" do
      
      before(:each) do
        @mock_request_token.stubs(:request_token?).returns(false)
      end
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should return a 401 error" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is request"
      end
    end
    
    describe "incorrectly signed" do
      
      def do_get
        @controller = get @uri.path + "/1", "Authorization" => @request["Authorization"]
      end
      
      it "should return a 401 error" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is request"
      end
    end
  end
  
  describe "require_access_token" do
    before(:each) do
      @uri = URI.parse('http://test.host/posts/access_token')
      @request = Net::HTTP::Get.new(@uri.path)
      
      @consumer = OAuth::Consumer.new('consumer_key', 'consumer_secret', :site => "http://test.host")
      @access_token = OAuth::AccessToken.new(@consumer, 'token', 'token_secret')
      
      @access_token.sign!(@request, {:nonce => 22557, :timestamp => "1199645624"})
      
      @mock_application = mock('consumer')
      @mock_application.stubs(:secret).returns('consumer_secret')
      
      @mock_access_token = mock('access_token')
      @mock_access_token.stubs(:secret).returns('token_secret')
      @mock_access_token.stubs(:access_token?).returns(true)
      
      Posts.any_instance.stubs(:find_token).with('token').returns(@mock_access_token)
      Posts.any_instance.stubs(:find_application_by_key).with('consumer_key').returns(@mock_application)
      Posts.any_instance.stubs(:request_already_happened?).returns(false)
    end
    
    describe "correctly signed" do
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should go through the before filter" do
        do_get
        @controller.body.should == "this is access"
      end
      
      it "should set the current_application" do
        do_get
        @controller.current_application.should == @mock_application
      end
      
      it "should set the current_token to nil" do
        do_get
        @controller.current_token.should == @mock_access_token
      end
    end
    
    describe "correctly signed but a replay attack (request has already been performed)" do
      
      before(:each) do
        Posts.any_instance.expects(:request_already_happened?).returns(true)
      end
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should return a 401 response" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is access"
      end
    end
    
    describe "correctly signed with with wrong token type" do
      
      before(:each) do
        @mock_access_token.stubs(:access_token?).returns(false)
      end
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should return a 401 error" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is access"
      end
    end
    
    describe "incorrectly signed" do
      
      def do_get
        @controller = get @uri.path + "/1", "Authorization" => @request["Authorization"]
      end
      
      it "should return a 401 error" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is request"
      end
    end
  end
  
  describe "require_signed_request" do
    
    before(:each) do
      @uri = URI.parse('http://test.host/posts/signed_request')
      @request = Net::HTTP::Get.new(@uri.path)
      
      @consumer = OAuth::Consumer.new('consumer_key', 'consumer_secret', :site => "http://test.host")
      
      @consumer.sign!(@request, nil, {:nonce => 22557, :timestamp => "1199645624"})
      
      @mock_application = mock('consumer')
      @mock_application.stubs(:secret).returns('consumer_secret')
      
      Posts.any_instance.stubs(:find_token).returns(nil)
      Posts.any_instance.stubs(:find_application_by_key).with('consumer_key').returns(@mock_application)
      Posts.any_instance.stubs(:request_already_happened?).returns(false)
    end
    
    describe "correctly signed" do
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should go through the before filter" do
        do_get
        @controller.body.should == "this is signed"
      end
      
      it "should set the current_application" do
        do_get
        @controller.current_application.should == @mock_application
      end
      
      it "should set the current_token to nil" do
        do_get
        @controller.current_token.should be_nil
      end
    end
    
    describe "correctly signed but a replay attack (request has already been performed)" do
      
      before(:each) do
        Posts.any_instance.expects(:request_already_happened?).returns(true)
      end
      
      def do_get
        @controller = get @uri.path, "Authorization" => @request['Authorization'] 
      end
      
      it "should return a 401 response" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is signed"
      end
    end
    
    describe "incorrectly signed" do
      
      def do_get
        @controller = get @uri.path + "/1", "Authorization" => @request["Authorization"]
      end
      
      it "should return a 401 error" do
        do_get
        @controller.status.should == 401
      end
      
      it "should halt before reaching the action" do
        do_get
        @controller.body.should_not == "this is signed"
      end
    end
    
  end
  
end