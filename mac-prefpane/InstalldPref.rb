require 'osx/cocoa'

include OSX

OSX.require_framework 'PreferencePanes'

require 'settings'
require 'launch_agent'
require 'sync'
require 'sync_connection'

class PrefPaneInstalld < NSPreferencePane
  
  ib_outlet :username
  ib_outlet :password
  ib_outlet :iTunesDirectory
  ib_outlet :lastSyncStatus
  
  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
    @settings = Settings.new(bundle.bundleIdentifier)
    @username.stringValue = @settings.username
    @password.stringValue = @settings.password
    @iTunesDirectory.stringValue = @settings.itunes_directory
    @launch_agent = LaunchAgent.new(bundle)
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
