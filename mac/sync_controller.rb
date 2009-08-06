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

OSX.load_bridge_support_file(OSX::NSBundle.mainBundle.pathForResource_ofType('Security', 'bridgesupport'))

class SyncController < OSX::NSObject
  
  include OSX
  
  ib_outlets :username, :password, :hoursBetweenSyncs, :autoLaunch, :menu, :preferencesWindow
  
  def awakeFromNib
    @status_bar = StatusBar.new(@menu)
    @preferences = Preferences.new
    
    @username.stringValue = @preferences.username
    @password.stringValue = @preferences.password
    @hoursBetweenSyncs.stringValue = @preferences.hours_between_syncs
    @autoLaunch.state = @preferences.auto_launch_enabled ? NSOnState : NSOffState
    
    setTimer
    
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
    username = @preferences.username
    password = @preferences.password
    
    doc = Sync.extract_data
    timestamp = Time.now.getlocal.strftime('%H:%M %a %d %B')
    if Sync.send_data(username, password, doc)
      @status_bar.last_sync_item.title = "Last synced #{timestamp}"
      @status_bar.clear_error
    else
      @status_bar.last_sync_item.title = "Sync failed #{timestamp}"
      @status_bar.set_error
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
  
end