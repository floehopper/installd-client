require 'osx/cocoa'

class MenuController < OSX::NSObject

  include OSX
  
  ib_outlet :menu
  ib_outlet :syncNowMenuItem
  ib_outlet :lastSyncStatusMenuItem
  
  SYNC_BUNDLE_IDENTIFIER = 'com.floehopper.installdSync'
  
  PREF_PANE_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', '..', '..', 'Installd.prefpane'))
  
  ANIMATION_TIME_INTERVAL = 0.2
  
  def awakeFromNib
    NSLog("InstalldMenu: awakeFromNib")
    
    bundle = NSBundle.bundleWithPath(PREF_PANE_PATH)
    @updater = SUUpdater.updaterForBundle(bundle)
    @updater.setAutomaticallyChecksForUpdates(true)
    @updater.resetUpdateCycle
    # @updater.checkForUpdatesInBackground
    
    @preferences = Installd::Preferences.new(SYNC_BUNDLE_IDENTIFIER)
    
    @status_bar_item = Installd::StatusBarItem.new(NSBundle.mainBundle, @menu)
    set_status_bar_item_visibility(@preferences.status_bar_enabled)
    displayLastSyncStatus(@preferences.last_sync_status)
    
    @notifications = Installd::Notifications.new('com.floehopper.installdSync')
    @notifications.register_for_sync_did_begin(self, "didBeginSync:")
    @notifications.register_for_sync_did_complete(self, "didCompleteSync:")
    @notifications.register_for_check_for_updates(self, "checkForUpdates:")
    @notifications.register_for_show_status_bar_item(self, "showStatusBarItem:")
    
    center = NSWorkspace.sharedWorkspace.notificationCenter
    center.addObserver_selector_name_object(
      self,
      "didTerminateApplication:",
      NSWorkspaceDidTerminateApplicationNotification,
      nil
    )
    
    sync_script = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'sync.sh'))
    @sync_agent = Installd::LaunchAgent.new(SYNC_BUNDLE_IDENTIFIER, sync_script) do |agent|
      agent.start_interval = 24 * 60 * 60
      agent.nice_increment = 10
    end
    @sync_agent.unload
    @sync_agent.write
    @sync_agent.load
  end
  
  # actions
  
  ib_action :syncNow do |sender|
    NSLog("InstalldMenu: syncNow")
    @sync_agent.start
  end
  
  ib_action :showPreferences do |sender|
    NSLog("InstalldMenu: showPreferences")
    NSWorkspace.sharedWorkspace.openFile(PREF_PANE_PATH)
  end
  
  ib_action :showWebsite do |sender|
    url = NSURL.URLWithString("http://installd.com/users/#{@preferences.username}")
    NSWorkspace.sharedWorkspace.openURL(url)
  end
  
  # notification handlers
  
  def didBeginSync(notification)
    NSLog("InstalldMenu: didBeginSync")
    @syncNowMenuItem.enabled = false
    @timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(ANIMATION_TIME_INTERVAL, self, 'animateIcon', { 'index' => 1 }, true)
  end
  
  def didCompleteSync(notification)
    NSLog("InstalldMenu: didCompleteSync")
    @timer.invalidate
    @timer = nil
    @syncNowMenuItem.enabled = true
    user_info = notification.userInfo
    return unless user_info
    return unless status = user_info['status']
    displayLastSyncStatus(status)
  end
  
  def checkForUpdates(notification)
    NSLog("InstalldMenu: checkForUpdates")
    @updater.checkForUpdates(self)
  end
  
  def showStatusBarItem(notification)
    NSLog("InstalldMenu: showStatusBarItem")
    user_info = notification.userInfo
    return unless user_info
    return unless state = user_info['state']
    set_status_bar_item_visibility(state.boolValue)
  end
  
  def didTerminateApplication(notification)
    NSLog("InstalldMenu: didTerminateApplication")
    user_info = notification.userInfo
    return unless user_info
    return unless appID = user_info['NSApplicationBundleIdentifier']
    if appID == 'com.apple.iTunes'
      @sync_agent.start unless @sync_agent.running?
    end
  end
  
  # methods
  
  def displayLastSyncStatus(status)
    NSLog("InstalldMenu: displayLastSyncStatus")
    if status.to_s =~ /fail/i
      @status_bar_item.set_error
    else
      @status_bar_item.clear_error
    end
    @lastSyncStatusMenuItem.title = status
  end
  
  def set_status_bar_item_visibility(state)
    NSLog("InstalldMenu: set_status_bar_item_visibility")
    @status_bar_item.set_visible(state)
  end
  
  def animateIcon(timer)
    NSLog("InstalldMenu: animateIcon")
    index = timer.userInfo['index'].to_i
    timer.userInfo['index'] = index + 1
    @status_bar_item.animate(index)
  end
  
end
