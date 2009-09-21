require 'cgi'
require 'base64'

class SyncConnection
  
  include OSX
  
  attr_accessor :on_success, :on_failure
  
  def send_data(username, password, doc)
    NSLog("username: #{username}")
    NSLog("password: #{password}")
    host = ENV['LOCAL'] ? "installd.local" : "installd.com"
    NSLog("Using host: #{host}")
    
    params_hash = { '_method' => 'put', 'doc' => doc }
    params = params_hash.inject('') { |v,i| v << "#{i[0].to_s}=#{CGI.escape(i[1].to_s)}&"}.chop
    params_data = NSString.stringWithString(params).dataUsingEncoding(NSASCIIStringEncoding)
    
    url = NSURL.URLWithString("https://#{host}/users/#{username}/installs/synchronize")
    
    request = NSMutableURLRequest.requestWithURL_cachePolicy_timeoutInterval(url, NSURLRequestUseProtocolCachePolicy, 30.0)
    credentials = ["#{username}:#{password}"].pack('m').chomp
    request.addValue_forHTTPHeaderField("Basic #{credentials}", 'Authorization')
    request.setHTTPMethod('put')
    request.setHTTPBody(params_data)
    request.addValue_forHTTPHeaderField(params_data.length.to_s, 'Content-Length')
    request.addValue_forHTTPHeaderField('application/x-www-form-urlencoded', 'Content-Type')
    
    @redirectCount = 0
    @connection = NSURLConnection.alloc.initWithRequest_delegate(request, self)
    unless @connection
      raise 'NSURLConnection could not create connection'
    end
  end
  
  def connection_willSendRequest_redirectResponse(connection, request, redirectResponse)
    NSLog('*** connection_willSendRequest_redirectResponse ***')
    @redirectCount += 1
    request
  end
  
  def connection_didReceiveResponse(connection, response)
    NSLog('*** connection_didReceiveResponse ***')
    @statusCode = response.statusCode
  end
  
  def connectionDidFinishLoading(connection)
    NSLog('*** connectionDidFinishLoading ***')
    NSLog("*** statusCode: #{@statusCode}") if @statusCode
    NSLog("*** redirectCount: #{@redirectCount}") if @redirectCount
    @connection = nil
    # For some reason (presumably to do with HTTP Auth), there is one 'redirect' even on a successful sync
    if (@statusCode.to_s == '200') && (@redirectCount <= 1)
      on_success.call
    else
      on_failure.call
    end
  end
  
  def connection_didFailWithError(connection, error)
    NSLog('*** connection_didFailWithError ***')
    NSLog("*** error: #{error.localizedDescription}")
    @connection = nil
    on_failure.call
  end
  
end
