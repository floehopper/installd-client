#!/usr/bin/env ruby

require 'osx/cocoa'

include OSX

require File.expand_path(File.join(File.dirname(__FILE__), 'preferences'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync'))
require File.expand_path(File.join(File.dirname(__FILE__), 'sync_connection'))

@preferences = Preferences.new

begin
  sync = Installd::Sync.new(@preferences.itunes_directory)
  doc = sync.extract_data
  timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
  
  NSLog("*** Sync begins ***")
  @connection = SyncConnection.new
  request = @connection.build_request(@preferences.username, @preferences.password, doc)
  data, response, error = NSURLConnection.sendSynchronousRequest_returningResponse_error(request)
  if error
    NSLog("*** Sync error: #{error.localizedDescription}")
  elsif (response.statusCode.to_s == '200')
    NSLog("*** Sync ends ***")
    @preferences.last_sync_status = "Last synced #{timestamp}"
  else
    NSLog("*** Sync failed: #{response.statusCode} ***")
    @preferences.last_sync_status = "Sync failed #{timestamp}"
  end
  @preferences.save
rescue => exception
  NSLog("*** Sync failed with exception: #{exception} ***")
  exception.backtrace.each do |line|
    NSLog("  #{line}")
  end
end