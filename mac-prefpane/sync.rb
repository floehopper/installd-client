require 'osx/cocoa'

require File.expand_path(File.join(File.dirname(__FILE__), 'settings'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))
require File.expand_path(File.join(File.dirname(__FILE__), 'notifications'))

module Installd
  
  class Sync
    
    include OSX
    
    def execute
      bundle_identifier = 'com.floehopper.installdPrefPane'
      settings = Settings.new(bundle_identifier)
      
      begin
        iphone_apps = IphoneApps.new(settings.itunes_directory)
        data = iphone_apps.extract_data
        timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
        
        NSLog("*** Sync begins ***")
        connection = SyncConnection.new(settings.username, settings.password)
        connection.synchronize(data)
        NSLog("*** Sync ends ***")
        
        settings.last_sync_status = "Last synced #{timestamp}"
      rescue => exception
        settings.last_sync_status = "Sync failed #{timestamp}"
        NSLog("*** Sync failed with exception: #{exception} ***")
        exception.backtrace.each do |line|
          NSLog("  #{line}")
        end
      end
      
      settings.save
      
      notifications = Notifications.new(bundle_identifier)
      notifications.sync_did_complete(settings.last_sync_status)
    end
    
  end
  
end

