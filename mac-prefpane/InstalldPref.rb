#
#  InstalldPref.m
#  Installd
#
#  Created by James Mead on 19/09/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'osx/cocoa'

include OSX

OSX.require_framework 'PreferencePanes'

require 'preferences'
require 'sync'
require 'sync_connection'
require 'command'

class PrefPaneInstalld < NSPreferencePane
  
  ib_outlet :username
  ib_outlet :password
  ib_outlet :iTunesDirectory
  ib_outlet :lastSyncStatus
  
  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
    @preferences = Preferences.new
    @username.stringValue = @preferences.username
    @password.stringValue = @preferences.password
    @iTunesDirectory.stringValue = @preferences.itunes_directory
    sync_script = bundle.pathForResource_ofType('sync', 'sh')
    plist = %{
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{bundle.bundleIdentifier}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{sync_script}</string>
          </array>
          <key>StartInterval</key>
          <integer>120</integer>
        </dict>
      </plist>
    }
    launch_agent_path = File.join(ENV['HOME'], 'Library', 'LaunchAgents', "#{bundle.bundleIdentifier}.plist")
    if File.exist?(launch_agent_path)
      Command.new(%{/bin/launchctl unload #{launch_agent_path}}).execute
    end
    File.open(launch_agent_path, 'w') do |file|
      file << plist
    end
    Command.new(%{/bin/launchctl load #{launch_agent_path}}).execute
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
    Command.new(%{/bin/launchctl start #{bundle.bundleIdentifier}}).execute
  end
  
  ib_action :chooseiTunesDirectory do |sender|
    NSLog("PrefPaneInstalld: chooseiTunesDirectory")
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(@preferences.itunes_directory, nil, nil, nil, self, 'openPanelDidEnd', nil)
  end
  
  def openPanelDidEnd(panel, returnCode, contextInfo = nil)
    NSLog("PrefPaneInstalld: openPanelDidEnd")
    if returnCode == NSOKButton
      @iTunesDirectory.stringValue = panel.directory
    end
  end
  
  private
  
  def save
    @preferences.username = @username.stringValue.to_s
    @preferences.password = @password.stringValue.to_s
    @preferences.itunes_directory = @iTunesDirectory.stringValue.to_s
    @preferences.save
  end
  
end
