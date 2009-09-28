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
    
    @updater = SUUpdater.updaterForBundle(bundle)
    @updater.setAutomaticallyChecksForUpdates(true)
    @updater.resetUpdateCycle
    @checkForUpdates.target = @updater
    @checkForUpdates.action = "checkForUpdates:"
    
    @notifications = Installd::Notifications.new(bundle.bundleIdentifier)
    @notifications.register_for_sync_did_complete(self, "didCompleteSync:")
  end
  
  def didCompleteSync(notification)
    NSLog("PrefPaneInstalld: didCompleteSync")
    user_info = notification.userInfo
    if user_info && user_info['status']
      @lastSyncStatus.stringValue = user_info['status']
    end
  end
  
  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
    @settings = Installd::Settings.new(bundle.bundleIdentifier)
    @username.stringValue = @settings.username
    @password.stringValue = @settings.password
    @iTunesDirectory.stringValue = @settings.itunes_directory
    @lastSyncStatus.stringValue = @settings.last_sync_status
    version = bundle.infoDictionary['CFBundleShortVersionString'] 
    @version.stringValue = version
    
    @launch_agent = Installd::LaunchAgent.new(bundle)
    @launch_agent.unload
    @launch_agent.write
    @launch_agent.load
  end
  
  def willSelect
    NSLog("PrefPaneInstalld: willSelect")
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
    save
  end
  
  def didUnselect
    NSLog("PrefPaneInstalld: didUnselect")
  end
  
  ib_action :syncNow do |sender|
    NSLog("PrefPaneInstalld: syncNow")
    save
    @launch_agent.start
  end
  
  ib_action :chooseiTunesDirectory do |sender|
    NSLog("PrefPaneInstalld: chooseiTunesDirectory")
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(@settings.itunes_directory, nil, nil, nil, self, 'openPanelDidEnd', nil)
  end
  
  def openPanelDidEnd(panel, returnCode, contextInfo = nil)
    NSLog("PrefPaneInstalld: openPanelDidEnd")
    if returnCode == NSOKButton
      @iTunesDirectory.stringValue = panel.directory
    end
  end
  
  private
  
  def save
    @settings.username = @username.stringValue.to_s
    @settings.password = @password.stringValue.to_s
    @settings.itunes_directory = @iTunesDirectory.stringValue.to_s
    @settings.save
  end
  
end
