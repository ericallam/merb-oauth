require File.dirname(__FILE__) + '/spec_helper'

describe OAuth::RequestProxy::MerbRequest do

  describe "#method" do
    it "should be the merb method capitalized" do
      @request = Merb::Request.new("REQUEST_METHOD" => "get")
      @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
      @proxy.method.should == "GET"
    end
  end
  
  describe "#uri" do
    it "should be the protocol + host + path" do
      @request = Merb::Request.new("REQUEST_PATH" => "/bloggers?asjdlkajsd=asdkjaksd", "HTTP_HOST" => "localhost")
      @proxy = OAuth::RequestProxy::MerbRequest.new(@request)

      @proxy.uri.should == "http://localhost/bloggers"
    end
  end
  
  describe "#parameters" do
    describe "clobbered" do
      it "should use options[:parameters]" do
        @proxy = OAuth::RequestProxy::MerbRequest.new(Merb::Request.new({}), {:clobber_request => true, :parameters => {:key => "value"}})
        @proxy.parameters[:key].should == "value"
      end
    end
    
    describe "all" do
      
    end
  end
  
  describe "#query_params" do
    it "should be merbs query string" do
      @request = Merb::Request.new("QUERY_STRING" => "key=value")
      @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
      @proxy.query_params.should == "key=value"
    end
  end
  
  describe "#post_params" do
    it "should be merbs raw post" do
      @request = Merb::Request.new('rack.input' => StringIO.new("key=value"))
      @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
      @proxy.post_params.should == "key=value"
    end
  end
  
  describe "auth_header_params" do
   %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each do |auth_header|
      describe "using #{auth_header}" do
        describe "starting with OAuth " do
          it do
            @request = Merb::Request.new(auth_header => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\"")
            @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
            @proxy.auth_header_params.should == "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""
          end
        end

        describe "not starting with OAuth " do
          it do
            @request = Merb::Request.new(auth_header => "OAuth1 realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\"")
            @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
            @proxy.auth_header_params.should be_empty
          end
        end # not starting with OAuth
      end # using AUTH HEADER
    end # %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each
  end # auth_header_params
  
  describe "#header_params" do
    %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each do |auth_header|
      describe "using #{auth_header}" do
        describe "starting with OAuth " do
          it do
            @request = Merb::Request.new(auth_header => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\"")
            @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
            @proxy.header_params.should == "oauth_nonce=cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"
          end
        end

        describe "not starting with OAuth " do
          it do
            @request = Merb::Request.new(auth_header => "OAuth1 realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\"")
            @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
            @proxy.header_params.should be_empty
          end
        end # not starting with OAuth
      end # using AUTH HEADER
    end # %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each
  end # header_params
  
  
  describe "#query_string" do
    it "should be header_params, post_params, and query_params joined by &" do
      @request = Merb::Request.new(
          'QUERY_STRING' => "query=value", 
          'rack.input' => StringIO.new("post=value"), 
          'Authorization' => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""
      )
          
      @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
      
      @proxy.query_string.should == ("query=value&post=value&oauth_nonce=cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ")
    end
  end
  
  describe "#all_parameters" do
    describe "with no options[:parameters]" do
      
      it "should build a hash of the key/value pairs" do
        @request = Merb::Request.new(
            'QUERY_STRING' => "query=value", 
            'rack.input' => StringIO.new("post=value"), 
            'Authorization' => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""
        )

        @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
        @proxy.all_parameters.should == {"query" => "value", "post" => "value", "oauth_nonce" => "cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"}
      end
      
      it "should return an array for any key that has more than 1 value" do
        @request = Merb::Request.new(
            'QUERY_STRING' => "query=value1", 
            'rack.input' => StringIO.new("query=value2"), 
            'Authorization' => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""
        )

        @proxy = OAuth::RequestProxy::MerbRequest.new(@request)
        @proxy.all_parameters.should == {"query" => ["value1", "value2"], "oauth_nonce" => "cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"}
      end
    end
    
    describe "with options[:parameters]" do
      it "should merge" do
        @request = Merb::Request.new(
            'QUERY_STRING' => "query=value1", 
            'rack.input' => StringIO.new("query=value2"), 
            'Authorization' => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""
        )

        @proxy = OAuth::RequestProxy::MerbRequest.new(@request, :parameters => {"query" => "value3", "key" => "value"})
        @proxy.all_parameters.should == {"query" => ["value1", "value2", "value3"], "key" => "value", "oauth_nonce" => "cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"}
      end # it should merge
    end # with options[:parameters]
  end # all_parameters
  
  
  # {
  #   "SERVER_NAME" => "localhost", "rack.input" => "", "rack.run_once" => false, "rack.url_scheme"=>"http", "PATH_INFO"=>"/bloggers", "rack.errors" => "", 
  #   "HTTP_AUTHORIZATION"=>"OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\", oauth_signature_method=\"HMAC-SHA1\", oauth_token=\"OjpHOz0G2tS5p8CHSBlcg\", oauth_timestamp=\"1212686612\", oauth_consumer_key=\"jOlAK275U7xkUEucyUrWBQ\", oauth_signature=\"0pJmcCZci3NyTXSBuUjJUwiVHCs%3D\", oauth_version=\"1.0\"", 
  #   "HTTP_HOST"=>"localhost:4000", "SERVER_PROTOCOL"=>"HTTP/1.1", "SCRIPT_NAME"=>"", "REQUEST_PATH"=>"/bloggers", "SERVER_SOFTWARE"=>"Mongrel 1.1.3", 
  #   "REMOTE_ADDR"=>"127.0.0.1", "rack.streaming"=>true, "rack.version"=>[0, 1], "rack.multithread"=>true, "HTTP_VERSION"=>"HTTP/1.1", 
  #   "rack.multiprocess"=>false, "REQUEST_URI"=>"/bloggers", "SERVER_PORT"=>"4000", "QUERY_STRING"=>"key=value", "GATEWAY_INTERFACE"=>"CGI/1.2", "HTTP_ACCEPT"=>"*/*", 
  #   "REQUEST_METHOD"=>"GET", "HTTP_CONNECTION"=>"close"
  # }

end