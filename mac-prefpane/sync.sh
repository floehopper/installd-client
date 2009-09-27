#!/usr/bin/env ruby

require 'osx/cocoa'

include OSX

require File.expand_path(File.join(File.dirname(__FILE__), 'settings'))
require File.expand_path(File.join(File.dirname(__FILE__), 'iphone_apps'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))

bundle_identifier = 'com.floehopper.installdPrefPane'
@settings = Installd::Settings.new(bundle_identifier)

begin
  iphone_apps = Installd::IphoneApps.new(@settings.itunes_directory)
  doc = iphone_apps.extract_data
  timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
  
  NSLog("*** Sync begins ***")
  @connection = Installd::SyncConnection.new
  request = @connection.build_request(@settings.username, @settings.password, doc)
  data, response, error = NSURLConnection.sendSynchronousRequest_returningResponse_error(request)
  if error
    NSLog("*** Sync error: #{error.localizedDescription}")
  elsif (response.statusCode.to_s == '200')
    NSLog("*** Sync ends ***")
    @settings.last_sync_status = "Last synced #{timestamp}"
  else
    NSLog("*** Sync failed: #{response.statusCode} ***")
    @settings.last_sync_status = "Sync failed #{timestamp}"
  end
  @settings.save
  NSLog(@settings.last_sync_status)
  
  center = NSDistributedNotificationCenter.defaultCenter
  center.postNotificationName_object_userInfo_deliverImmediately(
    "InstalldSyncDidComplete",
    bundle_identifier,
    { 'status' => @settings.last_sync_status },
    true
  )
rescue => exception
  NSLog("*** Sync failed with exception: #{exception} ***")
  exception.backtrace.each do |line|
    NSLog("  #{line}")
  end
end