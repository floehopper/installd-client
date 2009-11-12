require 'osx/cocoa'

require 'tempfile'

require File.expand_path(File.join(File.dirname(__FILE__), 'preferences'))
require File.expand_path(File.join(File.dirname(__FILE__), 'key_chain'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))
require File.expand_path(File.join(File.dirname(__FILE__), 'notifications'))

module Installd
  
  class Sync
    
    include OSX
    
    SYNC_BUNDLE_IDENTIFIER = 'com.floehopper.installdSync'
    
    def execute
      notifications = Notifications.new(SYNC_BUNDLE_IDENTIFIER)
      notifications.sync_did_begin
      
      preferences = Preferences.new(SYNC_BUNDLE_IDENTIFIER)
      key_chain = KeyChain.new(preferences.username)
      
      timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
      iphone_apps = IphoneApps.new(preferences.itunes_directory)
      
      Tempfile.open('output.xml') do |file|
        NSLog("Installd::Sync: unpacking begins")
        iphone_apps.extract_data(file)
        file.sync unless file.fsync
        NSLog("Installd::Sync: unpacking ends")
        
        NSLog("Installd::Sync: connection begins")
        connection = SyncConnection.new(preferences.username, key_chain.password)
        connection.synchronize(file)
        NSLog("Installd::Sync: connection ends")
      end
      
      status = "Last synced #{timestamp}"
    rescue => exception
      status = "Sync failed #{timestamp}"
      NSLog("Installd::Sync: failed with exception: #{exception}")
      exception.backtrace.each do |line|
        NSLog("  #{line}")
      end
    ensure
      notifications.sync_did_complete(status)
    end
    
  end
  
end

