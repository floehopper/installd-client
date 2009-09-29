require 'osx/cocoa'

require File.expand_path(File.join(File.dirname(__FILE__), 'preferences'))
require File.expand_path(File.join(File.dirname(__FILE__), 'key_chain'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))
require File.expand_path(File.join(File.dirname(__FILE__), 'notifications'))

module Installd
  
  class Sync
    
    include OSX
    
    def execute
      bundle_identifier = 'com.floehopper.installdPrefPane'
      
      notifications = Notifications.new(bundle_identifier)
      notifications.sync_did_begin
      
      preferences = Preferences.new(bundle_identifier)
      key_chain = KeyChain.new(preferences.username)
      
      begin
        iphone_apps = IphoneApps.new(preferences.itunes_directory)
        data = iphone_apps.extract_data
        timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
        
        NSLog("*** Sync begins ***")
        connection = SyncConnection.new(preferences.username, key_chain.password)
        connection.synchronize(data)
        NSLog("*** Sync ends ***")
        
        status = "Last synced #{timestamp}"
      rescue => exception
        status = "Sync failed #{timestamp}"
        NSLog("*** Sync failed with exception: #{exception} ***")
        exception.backtrace.each do |line|
          NSLog("  #{line}")
        end
      end
      
      notifications.sync_did_complete(status)
    end
    
  end
  
end

