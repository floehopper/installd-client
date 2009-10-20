require 'osx/cocoa'

module Installd
  
  class StatusBarItem
    
    include OSX
    
    NUMBER_OF_IMAGES = 16
    
    def initialize(bundle, menu)
      @bundle, @menu = bundle, menu
      @bar = NSStatusBar.systemStatusBar
      
      @app_icon = create_image('app')
      @app_alter_icon = create_image('app_a')
      @error_icon = create_image('error')
      @error_alter_icon = create_image('error_a')
      
      @images = Array.new(NUMBER_OF_IMAGES) do |index|
        create_image("app-#{index}")
      end
    end
    
    def set_visible(value)
      NSLog("Installd::StatusBarItem: set_visible")
      value ? show : hide
    end
    
    def show
      NSLog("Installd::StatusBarItem: show")
      unless @item
        @item = @bar.statusItemWithLength(24)
        @item.setHighlightMode(true)
        @item.setMenu(@menu)
        clear_error
      end
    end
    
    def hide
      NSLog("Installd::StatusBarItem: hide")
      if @item
        @bar.removeStatusItem(@item)
        @item = nil
      end
    end
    
    def clear_error
      NSLog("Installd::StatusBarItem: clear_error")
      if @item
        @item.setImage(@app_icon)
        @item.setAlternateImage(@app_alter_icon)
      end
    end
    
    def set_error
      NSLog("Installd::StatusBarItem: set_error")
      if @item
        @item.setImage(@error_icon)
        @item.setAlternateImage(@error_alter_icon)
      end
    end
    
    def animate(index)
      NSLog("Installd::StatusBarItem: animate")
      if @item
        @item.setImage(@images[index % NUMBER_OF_IMAGES])
      end
    end
    
    private
    
    def create_image(name)
      NSImage.alloc.initWithContentsOfFile(
        @bundle.pathForResource_ofType(name, 'png')
      )
    end
    
  end
  
end