require 'osx/cocoa'

class MenuController < OSX::NSObject

  include OSX
  
  ib_outlet :menu
  ib_outlet :syncNowMenuItem
  ib_outlet :lastSyncStatusMenuItem
  
  SYNC_BUNDLE_IDENTIFIER = 'com.floehopper.installdSync'
  
  ANIMATION_TIME_INTERVAL = 0.2
  NUMBER_OF_IMAGES = 16
  
  def awakeFromNib
    NSLog("InstalldMenu: awakeFromNib")
    
    bundle = NSBundle.bundleWithPath(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', '..', '..', 'Installd.prefpane')))
    @updater = SUUpdater.updaterForBundle(bundle)
    @updater.setAutomaticallyChecksForUpdates(true)
    @updater.resetUpdateCycle
    
    @preferences = Installd::Preferences.new(SYNC_BUNDLE_IDENTIFIER)
    
    @bundle = NSBundle.mainBundle
    
    @statusBar = NSStatusBar.systemStatusBar
    @statusItem = @statusBar.statusItemWithLength(24)
    @statusItem.setHighlightMode(true)
    @statusItem.setMenu(@menu)
    
    @app_icon = create_image('app')
    @app_alter_icon = create_image('app_a')
    @error_icon = create_image('error')
    @error_alter_icon =create_image('error_a')
    
    @images = Array.new(NUMBER_OF_IMAGES) { |index| create_image("app-#{index}") }
    
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
    @sync_agent.start
  end
  
  ib_action :showPreferences do |sender|
    NSLog("InstalldMenu: showPreferences")
    prefpane_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', '..', '..', 'Installd.prefpane'))
    NSWorkspace.sharedWorkspace.openFile(prefpane_path)
  end
  
  ib_action :showWebsite do |sender|
    url = NSURL.URLWithString("http://installd.com/users/#{@preferences.username}")
    NSWorkspace.sharedWorkspace.openURL(url)
  end
  
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
  
  def displayLastSyncStatus(status)
    NSLog("InstalldMenu: displayLastSyncStatus")
    if status.to_s =~ /fail/i
      @statusItem.setImage(@error_icon)
      @statusItem.setAlternateImage(@error_alter_icon)
    else
      @statusItem.setImage(@app_icon)
      @statusItem.setAlternateImage(@app_alter_icon)
    end
    @lastSyncStatusMenuItem.title = status
  end
  
  def animateIcon(timer)
    NSLog("InstalldMenu: animateIcon")
    index = timer.userInfo['index'].to_i
    timer.userInfo['index'] = index + 1
    @statusItem.setImage(@images[index % NUMBER_OF_IMAGES])
  end
  
  private
  
  def create_image(name)
    NSImage.alloc.initWithContentsOfFile(
      @bundle.pathForResource_ofType(name, 'png')
    )
  end
  
end
