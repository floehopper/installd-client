#!/usr/bin/env ruby

require 'osx/cocoa'

include OSX

require File.expand_path(File.join(File.dirname(__FILE__), 'settings'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))
require File.expand_path(File.join(File.dirname(__FILE__), 'notifications'))

bundle_identifier = 'com.floehopper.installdPrefPane'
settings = Installd::Settings.new(bundle_identifier)

begin
  iphone_apps = Installd::IphoneApps.new(settings.itunes_directory)
  data = iphone_apps.extract_data
  timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
  
  NSLog("*** Sync begins ***")
  connection = Installd::SyncConnection.new(settings.username, settings.password)
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

notifications = Installd::Notifications.new(bundle_identifier)
notifications.sync_did_complete(settings.last_sync_status)
