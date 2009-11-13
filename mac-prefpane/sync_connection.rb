require 'osx/cocoa'

require 'uri'
require 'net/http'
require 'net/https'
require 'md5'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'multipart-post', 'lib'))
require 'net/http/post/multipart'

module Installd

  class SyncConnection
  
    include OSX
    
    def initialize(username, password)
      @username, @password = username, password
      if local?
        scheme, host = 'https', 'installd.local'
      else
        scheme, host = 'https', 'installd.com'
      end
      url = "#{scheme}://#{host}/users/#{username}/events/synchronize"
      @uri = URI.parse(url)
    end
    
    def local?
      !ENV['LOCAL'].nil?
    end
    
    def synchronize(io)
      upload = UploadIO.new(io, 'text/plain', 'apps.xml')
      boundary = '-----------' + MD5.hexdigest(Time.now.to_s)
      params = { 'apps' => upload }
      headers = {}
      request = Net::HTTP::Put::Multipart.new(@uri.path, params, headers, boundary)
      request.basic_auth(@username, @password)
      
      http = Net::HTTP.new(@uri.host, @uri.port)
      if @uri.scheme == 'https'
        http.use_ssl = true
        if local?
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          http.ca_file = File.expand_path(File.join(File.dirname(__FILE__), 'cacert.pem'))
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
      end
      
      response = http.start { |http| http.request(request) }
      response.error! unless Net::HTTPOK === response
    end
    
  end

end