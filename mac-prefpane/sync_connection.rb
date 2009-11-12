require 'osx/cocoa'

require 'cgi'
require 'md5'


module Installd

  class SyncConnection
  
    include OSX
    
    def initialize(username, password)
      @username, @password = username, password
    end
    
    def build_request(file)
      if ENV['LOCAL']
        protocol = 'https'
        host = 'installd.local'
      else
        protocol = 'https'
        host = 'installd.com'
      end
      
      boundary = MD5.hexdigest(Time.now.to_s)
      data = NSData.dataWithContentsOfFile(file.path)
      
      name = 'output'
      filename = 'output.xml'
      
      post_data = NSMutableData.dataWithCapacity(data.length + 512)
      post_data.appendData(encoded("--#{boundary}\r\n"))
      post_data.appendData(encoded(%{Content-Disposition: form-data; name="#{name}"; filename="#{filename}"\r\n\r\n}))
      post_data.appendData(data)
      post_data.appendData(encoded("--#{boundary}--\r\n"))
      
      url = NSURL.URLWithString("#{protocol}://#{host}/users/#{@username}/events/synchronize")
          
      request = NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, NSURLRequestUseProtocolCachePolicy, 30.0)
      credentials = ["#{@username}:#{@password}"].pack('m').chomp
      request.addValue_forHTTPHeaderField("Basic #{credentials}", 'Authorization')
      request.setHTTPMethod('put')
      request.setHTTPBody(post_data)
      request.addValue_forHTTPHeaderField(post_data.length.to_s, 'Content-Length')
      request.addValue_forHTTPHeaderField("multipart/form-data; boundary=#{boundary}", 'Content-Type')
      request
    end
    
    def synchronize(file)
      request = build_request(file)
      data, response, error = NSURLConnection.sendSynchronousRequest_returningResponse_error(request)
      raise "Sync error: #{error.localizedDescription}" if error
      raise "Sync failed: #{response.statusCode}" unless (response.statusCode.to_s == '200')
    end
    
    private
    
    def encoded(string)
      NSString.stringWithString(string).dataUsingEncoding(NSUTF8StringEncoding)
    end
    
  end

end