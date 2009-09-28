require 'osx/cocoa'

OSX.require_framework 'PreferencePanes'

require File.expand_path(File.join(File.dirname(__FILE__), 'settings'))
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
  
  def awakeFromNib
    NSLog("PrefPaneInstalld: awakeFromNib")
  end
  
  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
    
    @updater = SUUpdater.updaterForBundle(bundle)
    @updater.setAutomaticallyChecksForUpdates(true)
    @updater.resetUpdateCycle
    @checkForUpdates.target = @updater
    @checkForUpdates.action = "checkForUpdates:"
    
    @notifications = Installd::Notifications.new(bundle.bundleIdentifier)
    @notifications.register_for_sync_did_complete(self, "didCompleteSync:")
    
    @settings = Installd::Settings.new(bundle.bundleIdentifier)
    
    @launch_agent = Installd::LaunchAgent.new(bundle)
    @launch_agent.unload
    @launch_agent.write
    @launch_agent.load
  end
  
  def willSelect
    NSLog("PrefPaneInstalld: willSelect")
    
    @settings.load
    
    @username.stringValue = @settings.username
    @password.stringValue = @settings.password
    @iTunesDirectory.stringValue = @settings.itunes_directory
    displayLastSyncStatus(@settings.last_sync_status)
    version = bundle.infoDictionary['CFBundleShortVersionString'] 
    @version.stringValue = version
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
    @settings.save
  end
  
  def didUnselect
    NSLog("PrefPaneInstalld: didUnselect")
  end
  
  ib_action :syncNow do |sender|
    NSLog("PrefPaneInstalld: syncNow")
    updateUsername(self)
    updatePassword(self)
    @settings.save
    @launch_agent.start
  end
  
  ib_action :chooseiTunesDirectory do |sender|
    NSLog("PrefPaneInstalld: chooseiTunesDirectory")
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(@settings.itunes_directory, nil, nil, nil, self, 'openPanelDidEnd', nil)
  end
  
  ib_action :updateUsername do |sender|
    NSLog("PrefPaneInstalld: updateUsername")
    @settings.username = @username.stringValue.to_s
  end
  
  ib_action :updatePassword do |sender|
    NSLog("PrefPaneInstalld: updatePassword")
    @settings.password = @password.stringValue.to_s
  end
  
  def openPanelDidEnd(panel, returnCode, contextInfo = nil)
    NSLog("PrefPaneInstalld: openPanelDidEnd")
    if returnCode == NSOKButton
      @iTunesDirectory.stringValue = panel.directory
      @settings.itunes_directory = panel.directory
    end
  end
  
  def didCompleteSync(notification)
    NSLog("PrefPaneInstalld: didCompleteSync")
    user_info = notification.userInfo
    return unless user_info
    return unless status = user_info['status']
    @settings.last_sync_status = status
    displayLastSyncStatus(status)
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
  
end
