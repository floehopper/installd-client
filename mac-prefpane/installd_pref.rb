require 'osx/cocoa'

OSX.require_framework 'PreferencePanes'

require File.expand_path(File.join(File.dirname(__FILE__), 'preferences'))
require File.expand_path(File.join(File.dirname(__FILE__), 'key_chain'))
require File.expand_path(File.join(File.dirname(__FILE__), 'launch_agent'))
require File.expand_path(File.join(File.dirname(__FILE__), 'notifications'))

class PrefPaneInstalld < OSX::NSPreferencePane
  
  include OSX
  
  ib_outlet :username
  ib_outlet :password
  ib_outlet :iTunesDirectory
  ib_outlet :lastSyncStatus
  ib_outlet :checkForUpdates
  ib_outlet :version
  ib_outlet :syncProgress
  ib_outlet :syncNow
  ib_outlet :statusBarCheckbox
  
  OLD_APP_BUNDLE_IDENTIFIER = 'com.floehopper.installdApp'
  SYNC_BUNDLE_IDENTIFIER = 'com.floehopper.installdSync'
  MENU_APP_BUNDLE_IDENTIFIER = 'com.floehopper.installdMenuApp'
  
  def awakeFromNib
    NSLog("PrefPaneInstalld: awakeFromNib")
  end
  
  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
    
    @notifications = Installd::Notifications.new(SYNC_BUNDLE_IDENTIFIER)
    @notifications.register_for_sync_did_begin(self, "didBeginSync:")
    @notifications.register_for_sync_did_complete(self, "didCompleteSync:")
    
    @preferences = Installd::Preferences.new(SYNC_BUNDLE_IDENTIFIER)
    migrateOldPreferences unless @preferences.launched_before
    
    sync_script = File.expand_path(File.join(File.dirname(__FILE__), 'sync.sh'))
    
    old_sync_agent = Installd::LaunchAgent.new(bundle.bundleIdentifier, sync_script)
    old_sync_agent.unload if old_sync_agent.loaded?
    old_sync_agent.delete
    
    @sync_agent = Installd::LaunchAgent.new(SYNC_BUNDLE_IDENTIFIER, sync_script) do |agent|
      agent.start_interval = 24 * 60 * 60
      agent.nice_increment = 10
    end
    @sync_agent.unload
    @sync_agent.write
    @sync_agent.load
    
    status_bar_app_path = File.expand_path(File.join(File.dirname(__FILE__), 'InstalldMenu.app'))
    status_bar_exe_path = File.expand_path(File.join(status_bar_app_path, 'Contents', 'MacOS', 'InstalldMenu'))
    @status_bar_agent = Installd::LaunchAgent.new(MENU_APP_BUNDLE_IDENTIFIER, status_bar_exe_path) do |agent|
      agent.run_at_load = true
    end
    @status_bar_agent.unload
    @status_bar_agent.write
    @status_bar_agent.load
    
    version = bundle.infoDictionary['CFBundleShortVersionString'] 
    @version.stringValue = version
    
    @statusBarCheckbox.state = (@preferences.status_bar_enabled ? NSOnState : NSOffState)
  end
  
  def willSelect
    NSLog("PrefPaneInstalld: willSelect")
    
    @preferences.load
    @username.stringValue = @preferences.username
    @iTunesDirectory.stringValue = @preferences.itunes_directory
    displayLastSyncStatus(@preferences.last_sync_status)
    
    key_chain = Installd::KeyChain.new(@preferences.username)
    @password.stringValue = key_chain.password
  end
  
  def didSelect
    NSLog("PrefPaneInstalld: didSelect")
  end
  
  def shouldUnselect
    NSLog("PrefPaneInstalld: shouldUnselect")
    NSUnselectNow
  end
  
  def willUnselect
    NSLog("PrefPaneInstalld: willUnselect")
    savePreferences
    saveKeyChain
  end
  
  def didUnselect
    NSLog("PrefPaneInstalld: didUnselect")
  end
  
  ib_action :syncNow do |sender|
    NSLog("PrefPaneInstalld: syncNow")
    didBeginSync(nil)
    savePreferences
    saveKeyChain
    @sync_agent.start
  end
  
  ib_action :chooseiTunesDirectory do |sender|
    NSLog("PrefPaneInstalld: chooseiTunesDirectory")
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(@preferences.itunes_directory, nil, nil, nil, self, 'openPanelDidEnd', nil)
  end
  
  ib_action :toggleStatusBar do |sender|
    NSLog("PrefPaneInstalld: toggleStatusBar")
    state = @statusBarCheckbox.state == NSOnState
    @notifications.show_status_bar_item(state)
  end
  
  ib_action :checkForUpdates do |sender|
    NSLog("PrefPaneInstalld: checkForUpdates")
    @notifications.check_for_updates
  end
  
  def openPanelDidEnd(panel, returnCode, contextInfo = nil)
    NSLog("PrefPaneInstalld: openPanelDidEnd")
    if returnCode == NSOKButton
      @iTunesDirectory.stringValue = panel.directory
    end
  end
  
  def didBeginSync(notification)
    NSLog("PrefPaneInstalld: didBeginSync")
    @syncNow.enabled = false
    @syncProgress.startAnimation(self)
  end
  
  def didCompleteSync(notification)
    NSLog("PrefPaneInstalld: didCompleteSync")
    @syncNow.enabled = true
    @syncProgress.stopAnimation(self)
    user_info = notification.userInfo
    return unless user_info
    return unless status = user_info['status']
    displayLastSyncStatus(status)
    savePreferences
  end
  
  def displayLastSyncStatus(status)
    NSLog("PrefPaneInstalld: displayLastSyncStatus")
    @lastSyncStatus.stringValue = status
    if status.to_s =~ /fail/i
      @lastSyncStatus.textColor = NSColor.redColor
    else
      @lastSyncStatus.textColor = NSColor.disabledControlTextColor
    end
  end
  
  def savePreferences
    NSLog("PrefPaneInstalld: savePreferences")
    @preferences.username = @username.stringValue.to_s
    @preferences.itunes_directory = @iTunesDirectory.stringValue.to_s
    @preferences.last_sync_status = @lastSyncStatus.stringValue.to_s
    @preferences.status_bar_enabled = (@statusBarCheckbox.state == NSOnState) ? true : false
    @preferences.save
  end
    
  def saveKeyChain
    NSLog("PrefPaneInstalld: saveKeyChain")
    key_chain = Installd::KeyChain.new(@preferences.username)
    key_chain.password = @password.stringValue.to_s
    key_chain.save
  end
  
  def migrateOldPreferences
    NSLog("PrefPaneInstalld: migrateOldPreferences")
    old_preferences = Installd::Preferences.new(OLD_APP_BUNDLE_IDENTIFIER)
    @preferences.username = old_preferences.username
    @preferences.itunes_directory = old_preferences.itunes_directory
    @preferences.launched_before = true
    @preferences.save
  end
  
end
