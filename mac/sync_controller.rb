#
#  sync_controller.rb
#  installd
#
#  Created by James Mead on 09/07/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'sync'
require 'preferences'

OSX.load_bridge_support_file(OSX::NSBundle.mainBundle.pathForResource_ofType('Security', 'bridgesupport'))

class SyncController < OSX::NSObject
  
  include OSX
  
  ib_outlets :username, :password, :hoursBetweenSyncs, :autoLaunch, :menu, :preferencesWindow
  
  def awakeFromNib
    @status_bar = NSStatusBar.systemStatusBar
    @status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
    @status_item.setHighlightMode(true)
    @status_item.setMenu(@menu)
    bundle = NSBundle.mainBundle
    @app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app', 'tiff'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app_a', 'tiff'))
    @status_item.setImage(@app_icon)
    @status_item.setAlternateImage(@app_alter_icon)
    
    @last_sync_item = NSMenuItem.alloc.init
    @last_sync_item.title = 'Not yet synced'
    @status_item.menu.insertItem_atIndex(@last_sync_item, 0)
    
    @preferences = Preferences.new
    
    @username.stringValue = @preferences.username if @preferences.username
    @password.stringValue = @preferences.password if @preferences.password
    @hoursBetweenSyncs.stringValue = @preferences.hours_between_syncs
    @autoLaunch.state = @preferences.auto_launch_enabled ? NSOnState : NSOffState
    
    setTimer
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
    Sync.send_data(username, password, doc)
    
    @last_sync_item.title = "Last synced #{Time.now.getlocal.strftime('%H:%M %a %d %B')}"
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
    @preferences.save
  end
  
end