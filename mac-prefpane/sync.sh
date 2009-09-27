#!/usr/bin/env ruby

require 'osx/cocoa'

include OSX

require File.expand_path(File.join(File.dirname(__FILE__), 'settings'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))

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

center = NSDistributedNotificationCenter.defaultCenter
center.postNotificationName_object_userInfo_deliverImmediately(
  "InstalldSyncDidComplete",
  bundle_identifier,
  { 'status' => settings.last_sync_status },
  true
)
