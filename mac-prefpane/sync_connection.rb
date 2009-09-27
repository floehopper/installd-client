require 'osx/cocoa'

require 'cgi'
require 'base64'

module Installd

  class SyncConnection
  
    include OSX
    
    def initialize(username, password)
      @username, @password = username, password
    end
    
    def build_request(doc)
      NSLog("username: #{@username}")
      NSLog("password: #{@password}")
      host = ENV['LOCAL'] ? "installd.local" : "installd.com"
      NSLog("Using host: #{host}")
    
      params_hash = { '_method' => 'put', 'doc' => @doc }
      params = params_hash.inject('') { |v,i| v << "#{i[0].to_s}=#{CGI.escape(i[1].to_s)}&"}.chop
      params_data = NSString.stringWithString(params).dataUsingEncoding(NSASCIIStringEncoding)
    
      url = NSURL.URLWithString("https://#{host}/users/#{@username}/installs/synchronize")
    
      request = NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, NSURLRequestUseProtocolCachePolicy, 30.0)
      credentials = ["#{@username}:#{@password}"].pack('m').chomp
      request.addValue_forHTTPHeaderField("Basic #{credentials}", 'Authorization')
      request.setHTTPMethod('put')
      request.setHTTPBody(params_data)
      request.addValue_forHTTPHeaderField(params_data.length.to_s, 'Content-Length')
      request.addValue_forHTTPHeaderField('application/x-www-form-urlencoded', 'Content-Type')
      request
    end
    
    def synchronize(doc)
      request = build_request(doc)
      data, response, error = NSURLConnection.sendSynchronousRequest_returningResponse_error(request)
      raise "Sync error: #{error.localizedDescription}" if error
      raise "Sync failed: #{response.statusCode}" unless (response.statusCode.to_s == '200')
    end
    
  end

end