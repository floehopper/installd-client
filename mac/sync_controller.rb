#
#  sync_controller.rb
#  installd
#
#  Created by James Mead on 09/07/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'sync'

OSX.load_bridge_support_file(OSX::NSBundle.mainBundle.pathForResource_ofType('Security', 'bridgesupport'))

class SyncController < OSX::NSObject
  
  include OSX
  
  SERVICE = 'Installd'
  
  ib_outlets :username, :password, :menu, :preferences
  
  def awakeFromNib
    @status_bar = NSStatusBar.systemStatusBar
    @status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
    @status_item.setHighlightMode(true)
    @status_item.setMenu(@menu)
    bundle = NSBundle.mainBundle
    @app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app', 'tiff'))
    @app_alter_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app_a', 'tiff'))
    @status_item.setImage(@app_icon)
    @status_item.setAlternateImage(@app_alter_icon)
    
    defaults = NSUserDefaults.standardUserDefaults
    username = defaults.stringForKey('username') || ''
    
    password = nil
    status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, username.length, username)
    if status == 0
      password_length = data.shift
      password_data = data.shift
      password = password_data.bytestr(password_length)
      NSLog("Found password in KeyChain: #{password}")
    else
      NSLog("Failed to find password in KeyChain: #{status}")
    end
    
    @username.stringValue = username if username
    @password.stringValue = password if password
  end
  
  ib_action :sync do |sender|
    username = @username.stringValue.to_s
    password = @password.stringValue.to_s
    
    doc = Sync.extract_data
    Sync.send_data(username, password, doc)
  end
  
  ib_action :showPreferencesWindow do |sender|
    NSApplication.sharedApplication.activateIgnoringOtherApps(true)
    @preferences.makeKeyAndOrderFront(sender)
  end
  
  ib_action :savePreferences do |sender|
    username = @username.stringValue.to_s
    password = @password.stringValue.to_s
    
    defaults = NSUserDefaults.standardUserDefaults
    defaults.setObject_forKey(username, 'username')
    defaults.synchronize
    
    status = SecKeychainAddGenericPassword(nil, SERVICE.length, SERVICE, username.length, username, password.length, password, nil)
    
    if status == 0
      NSLog("Password created in KeyChain: #{password}")
    elsif status == ErrSecDuplicateItem
      NSLog("Password already exists in KeyChain")
      status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, username.length, username)
      if status == 0
        password_length = data.shift
        password_data = data.shift
        item_reference = data.shift
        status = SecKeychainItemModifyContent(item_reference, nil, password.length, password)
        if status == 0
          NSLog("Password updated in KeyChain: #{password}")
        else
          NSLog("Failed to update password in KeyChain: #{status}")
        end
      else
        NSLog("Failed to find password in KeyChain: #{status}")
      end
    else
      NSLog("Failed to create password in KeyChain: #{status}")
    end
  end
  
end