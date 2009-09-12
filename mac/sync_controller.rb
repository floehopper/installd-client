#
#  sync_controller.rb
#  installd
#
#  Created by James Mead on 09/07/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'sync'
require 'status_bar'
require 'preferences'
require 'sync_connection'

OSX.load_bridge_support_file(OSX::NSBundle.mainBundle.pathForResource_ofType('Security', 'bridgesupport'))

class SyncController < OSX::NSObject
  
  include OSX
  
  ib_outlets :username, :password, :hoursBetweenSyncs, :autoLaunch, :menu, :preferencesWindow, :iTunesDirectory
  
  def awakeFromNib
    @status_bar = StatusBar.new(@menu)
    @preferences = Preferences.new
    
    @username.stringValue = @preferences.username
    @password.stringValue = @preferences.password
    @hoursBetweenSyncs.stringValue = @preferences.hours_between_syncs
    @autoLaunch.state = @preferences.auto_launch_enabled ? NSOnState : NSOffState
    @iTunesDirectory.stringValue = @preferences.itunes_directory
    
    setTimer
    
    @preferencesWindow.center
    
    unless @preferences.launched_before
      @preferences.auto_launch_enabled = true
      @autoLaunch.state = NSOnState
      @preferences.save
      showPreferencesWindow(self)
    end
  end
  
  def setTimer
    @timer.invalidate if @timer
    seconds_between_syncs = @preferences.hours_between_syncs * 60 * 60
    @timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(seconds_between_syncs, self, 'sync', nil, true)
  end
  
  ib_action :sync do |sender|
    begin
      sync = Sync.new(@preferences.itunes_directory)
      doc = sync.extract_data
      timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
      
      NSLog("*** Sync begins ***")
      @connection = SyncConnection.new
      @connection.on_success = Proc.new do
        NSLog("*** Sync ends ***")
        @status_bar.last_sync_item.title = "Last synced #{timestamp}"
        @status_bar.clear_error
      end
      @connection.on_failure = Proc.new do
        @status_bar.last_sync_item.title = "Sync failed #{timestamp}"
        @status_bar.set_error
      end
      @connection.send_data(@preferences.username, @preferences.password, doc)
    rescue => exception
      NSLog("Exception handled: #{exception}")
      exception.backtrace.each do |line|
        NSLog("  #{line}")
      end
      NSLog("*** Sync failed ***")
    end
  end
  
  ib_action :showPreferencesWindow do |sender|
    NSApplication.sharedApplication.activateIgnoringOtherApps(true)
    @preferencesWindow.makeKeyAndOrderFront(sender)
  end
  
  ib_action :savePreferences do |sender|
    @preferences.username = @username.stringValue.to_s
    @preferences.password = @password.stringValue.to_s
    @preferences.hours_between_syncs = Integer(@hoursBetweenSyncs.stringValue.to_s) rescue Preferences::DEFAULTS[:hours_between_syncs]
    @preferences.auto_launch_enabled = (@autoLaunch.state == NSOnState) ? true : false
    @preferences.itunes_directory = @iTunesDirectory.stringValue.to_s
    credentials_changed = @preferences.credentials_changed?
    @preferences.save
    
    @preferencesWindow.close
    
    if credentials_changed
      button_code = NSRunAlertPanel("Installd - Credentials Changed", "Your credentials have changed.\nDo you want to sync now?", "Yes", "No", nil)
      if button_code == 1
        sync(self)
      end
    end
  end
  
  ib_action :chooseDirectory do |sender|
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(@preferences.itunes_directory, nil, nil, nil, self, 'openPanelDidEnd', nil)
  end
  
  def openPanelDidEnd(panel, returnCode, contextInfo = nil)
    if returnCode == NSOKButton
      @iTunesDirectory.stringValue = panel.directory
    end
  end
  
end