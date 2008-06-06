require 'oauth/request_proxy/base'
require 'uri'
require 'cgi'

module OAuth::RequestProxy
  class MerbRequest < OAuth::RequestProxy::Base
    proxies Merb::Request

    # ==== Returns
    # <String>:: of the request method in the set:
    #  %w(GET PUT POST DELETE HEAD)
    def method
      request.method.to_s.upcase
    end

    # ==== Returns
    # <String> specifying the request uri without any query params
    def uri
      uri = URI.parse(request.protocol + request.host + request.path)
      uri.query = nil
      uri.to_s
    end

    # ==== Returns
    # <Hash>:: of parameters, if options[:clobber_request] == true
    # than we just return options[:parameters] which should be a Hash
    def parameters
      if options[:clobber_request]
        options[:parameters]
      else
        all_parameters
      end
    end

    # ==== Returns
    # <String>:: of the first Authorization header to contain a string
    #  that matches /^OAuth /
    def auth_header_params
      %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each do |header|
        return request.env[header] if request.env[header].to_s =~ /^OAuth /
      end 
      ''
    end
    
    
    # the OAuth parameters in the Merb::Request object
    # ==== Returns <String>
    # a String of key/value pairs suitable for a query_string eg:
    #
    #   oauth_nonce=asd90asdjasd&realm=aduasdklad
    # 
    # extracts the string from the headers in one of 3 places: 
    #   %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION )
    #
    # will only return a value if one of the three headers has a string
    # that matchs /^OAuth /
    #
    # ==== Example
    #
    #  request = Merb::Request.new('Authorization' => "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\"")
    #  proxy = OAuth::RequestProxy::MerbRequest.new(request)
    #  proxy.header_params
    #  # => oauth_nonce=cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ
    def header_params
      return auth_header_params if auth_header_params.empty?

      # drop the first 6 characters and then split on either = or ,
      # "OAuth realm=\"\", oauth_nonce=\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""  becomes:
      # ["realm", "\"\"", " oauth_nonce", "\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""]
      oauth_param_string = auth_header_params[6,auth_header_params.length].split(/[,=]/)
      
      # strip all the elements
      # ["realm", "\"\"", " oauth_nonce", "\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""] becomes
      # ["realm", "\"\"", "oauth_nonce", "\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""]
      oauth_param_string.map! { |v| v.strip }
      
      # get rid of \"
      # ["realm", "\"\"", "oauth_nonce", "\"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ\""] becomes
      # ["realm", "", "oauth_nonce", "cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"]
      oauth_param_string.map! { |v| v =~ /^\".*\"$/ ? v[1..-2] : v }
      
      # turn the array into a hash
      # ["realm", "", "oauth_nonce", "cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ"] becomes
      # {"oauth_nonce"=>"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ", "realm"=>""}
      oauth_params = Hash[*oauth_param_string.flatten]
      
      # drop any key/value pair that doesnt start with oauth
      oauth_params.reject! { |k,v| k !~ /^oauth_/ }
      
      # join the key/values into key=value strings, and join them with an &
      # {"oauth_nonce"=>"cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ", "oauth_realm"=>""} becomes:
      # "oauth_nonce=cSSbhV7zEgXeoskRuKV4VCAjq3uiUxFydEFzvCQDSzQ&oauth_realm="
      oauth_params.map { |k,v| "#{k}=#{v}" }.join('&')
    end

    # Merb::Request#query_string => @env['QUERY_STRING']
    def query_params
      request.query_string
    end

    # Merb::Request#raw_post => @env['rack.input']
    # NOTE: @env['rack.input'].is_a? StringIO => true
    # Merb::Request#raw_post will rewind and read the StringIO
    # before returning it
    def post_params
      p = request.send(:raw_post)
      p.blank? ? nil : p
    end

    # Combines the query_params, post_params, and header_params into one string
    # joined by &
    def query_string
      [ query_params, post_params, header_params ].compact.join('&')
    end

    # ==== Returns
    # <Hash>:: all the parameters found in the request
    #  as well as parameters passed in the options Hash
    def all_parameters
      # CGI.parse will turn a query string into a Hash
      # with values being an array of values
      # Example:
      # CGI.parse("hello=world&key=value1&key=value2")
      # #=> {"hello" => ["world"], "key" => ["value1", "value2"]}
      request_params = CGI.parse(query_string)

      # Merged options[:parameters] into the request_params local var
      # if the key already exists than push the value onto the stack
      # else create the key value making sure the value is an Array of depth 1
      if options[:parameters]
        options[:parameters].each do |key, value|
          if request_params.has_key?(key)
            request_params[key] << value
          else
            request_params[key] = [value].flatten
          end
        end
      end
      
      # Build a new hash where values with only 1 element are .to_s'ed
      # === Example:
      # 
      # {:two => ["3"], :one => ["1", "2"]} becomes:
      # {:two => "3", :one => ["1", "2"]}
      request_params.inject({}) do |params, (key, value)|
        params[key] = value.size == 1 ? value.to_s : value
        params
      end
    end

    def unescape(value)
      URI.unescape(value.gsub('+', '%2B'))
    end
  end
end
