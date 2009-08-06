class StatusBar
  
  include OSX
  
  attr_reader :last_sync_item
  
  def initialize(menu)
    @status_bar = NSStatusBar.systemStatusBar
    @status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
    @status_item.setHighlightMode(true)
    @status_item.setMenu(menu)
    bundle = NSBundle.mainBundle
    @app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app', 'tiff'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app_a', 'tiff'))
    @status_item.setImage(@app_icon)
    @status_item.setAlternateImage(@app_alter_icon)
    
    @last_sync_item = NSMenuItem.alloc.init
    @last_sync_item.title = 'Not yet synced'
    @status_item.menu.insertItem_atIndex(@last_sync_item, 0)
  end
  
end