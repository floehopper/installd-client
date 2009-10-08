require 'osx/cocoa'

class MenuController < OSX::NSObject

  include OSX
  
  ib_outlet :menu
  ib_outlet :syncNowMenuItem
  ib_outlet :lastSyncStatusMenuItem
  
  SYNC_BUNDLE_IDENTIFIER = 'com.floehopper.installdSync'
  
  def awakeFromNib
    NSLog("InstalldMenu: awakeFromNib")
    
    @preferences = Installd::Preferences.new(SYNC_BUNDLE_IDENTIFIER)
    
    @bundle = NSBundle.mainBundle
    
    @statusBar = NSStatusBar.systemStatusBar
    @statusItem = @statusBar.statusItemWithLength(NSSquareStatusItemLength)
    @statusItem.setHighlightMode(true)
    @statusItem.setMenu(@menu)
    
    @app_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('app', 'png'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('app_a', 'png'))
    @error_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('error', 'png'))
    @error_alter_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('error_a', 'png'))
    
    @notifications = Installd::Notifications.new('com.floehopper.installdSync')
    @notifications.register_for_sync_did_begin(self, "didBeginSync:")
    @notifications.register_for_sync_did_complete(self, "didCompleteSync:")
    
    sync_script = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'sync.sh'))
    @sync_agent = Installd::LaunchAgent.new(SYNC_BUNDLE_IDENTIFIER, sync_script) do |agent|
      agent.start_interval = 24 * 60 * 60
      agent.nice_increment = 10
    end
    @sync_agent.unload
    @sync_agent.write
    @sync_agent.load
    
    displayLastSyncStatus(@preferences.last_sync_status)
  end
  
  ib_action :syncNow do |sender|
    NSLog("InstalldMenu: syncNow")
    didBeginSync(nil)
    @sync_agent.start
  end
  
  ib_action :showPreferences do |sender|
    NSLog("InstalldMenu: showPreferences")
    prefpane_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', '..', 'Installd.prefpane'))
    NSWorkspace.sharedWorkspace.openFile(prefpane_path)
  end
  
  def didBeginSync(notification)
    NSLog("InstalldMenu: didBeginSync")
    @syncNowMenuItem.enabled = false
  end
  
  def didCompleteSync(notification)
    NSLog("InstalldMenu: didCompleteSync")
    @syncNowMenuItem.enabled = true
    user_info = notification.userInfo
    return unless user_info
    return unless status = user_info['status']
    displayLastSyncStatus(status)
  end
  
  def displayLastSyncStatus(status)
    if status.to_s =~ /fail/i
      @statusItem.setImage(@error_icon)
      @statusItem.setAlternateImage(@error_alter_icon)
    else
      @statusItem.setImage(@app_icon)
      @statusItem.setAlternateImage(@app_alter_icon)
    end
    @lastSyncStatusMenuItem.title = status
  end
  
end
