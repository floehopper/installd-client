require 'fileutils'

class Sync
  
  class << self
    
    include OSX
    
    def app_files
      apps_pattern = File.join(ENV['HOME'], 'Music', 'iTunes', 'Mobile Applications', '*.ipa')
      Dir[apps_pattern]
    end
    
    def extract_data
      FileUtils.mkdir_p('/tmp/installd/')
      
      FileUtils.rm_rf('/tmp/installd/unzipped')
      FileUtils.mkdir_p('/tmp/installd/unzipped')
      
      doc = ''
      app_files.each_with_index do |app_file, index|
        begin
          app_name = File.basename(app_file, '.ipa')
          unzip_dir = File.join('/tmp/installd/unzipped', app_name)
          plist = File.join(unzip_dir, 'iTunesMetadata.plist')
        
          execute %{/usr/bin/unzip -d "#{unzip_dir}" "#{app_file}" iTunesMetadata.plist}
          execute %{/bin/chmod +rw "#{plist}"}
          execute %{/usr/bin/plutil -convert xml1 "#{plist}"}
        
          File.open(plist) do |file|
            file.readline
            file.readline
            doc << file.read
          end
        
          yield index if block_given?
        rescue => exception
          NSLog("Exception handled: #{exception}")
          exception.backtrace.each do |line|
            NSLog("  #{line}")
          end
          NSLog("Skipping: #{app_file}")
        end
      end
      
      FileUtils.rm_rf('/tmp/installd/unzipped')
      
      doc
    end
    
    def send_data(username, password, doc)
      require 'net/http'
      require 'uri'
      
      NSLog("*** Sync begins ***")
      
      host = ENV['LOCAL'] ? "installd.local" : "installd.com"
      NSLog("Host: #{host}")
      
      url = "http://#{username}:#{password}@#{host}/users/#{username}/installs/synchronize"
      
      response = Net::HTTP.post_form(URI.parse(url), { '_method' => 'put', 'doc' => doc })
      unless response.code == '200'
        raise "Unexpected response code: #{response.code}"
      end
      
      NSLog("*** Sync ends ***")
    rescue => exception
      NSLog("Exception handled: #{exception}")
      exception.backtrace.each do |line|
        NSLog("  #{line}")
      end
      NSLog("*** Sync failed ***")
    end
    
    def execute(command)
      NSLog(command)
      NSLog(`#{command} 2>&1`)
      unless $?.success?
        message = "Error executing command: #{command}"
        NSLog(message)
        raise message
      end
    end
  
  end
  
end