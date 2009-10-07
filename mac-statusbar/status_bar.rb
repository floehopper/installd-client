class StatusBar
  
  include OSX
  
  # attr_reader :last_sync_item
  
  def initialize(bundle, menu)
    @bundle = bundle
    @status_bar = NSStatusBar.systemStatusBar
    @status_item = @status_bar.statusItemWithLength(NSSquareStatusItemLength)
    @status_item.setHighlightMode(true)
    @status_item.setMenu(menu)
    clear_error
    
    # @last_sync_item = NSMenuItem.alloc.init
    # @last_sync_item.title = 'Not yet synced'
    # @status_item.menu.insertItem_atIndex(@last_sync_item, 0)
  end
  
  def clear_error
    @app_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('app', 'tiff'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('app_a', 'tiff'))
    @status_item.setImage(@app_icon)
    @status_item.setAlternateImage(@app_alter_icon)
  end
  
  def set_error
    @app_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('error', 'tiff'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(@bundle.pathForResource_ofType('error_a', 'tiff'))
    @status_item.setImage(@app_icon)
    @status_item.setAlternateImage(@app_alter_icon)
  end
  
end