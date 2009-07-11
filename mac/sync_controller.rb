#
#  sync_controller.rb
#  installd
#
#  Created by James Mead on 09/07/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'sync'

OSX.require_framework 'Security'
OSX.load_bridge_support_file(OSX::NSBundle.mainBundle.pathForResource_ofType('Security', 'bridgesupport'))

class SyncController < OSX::NSObject
  
  include OSX
  
  SERVICE = 'Installd'
  
  ib_outlets :label, :username, :password
  
  def awakeFromNib
    defaults = NSUserDefaults.standardUserDefaults
    username = defaults.stringForKey('username') || ''
    
    password = nil
    status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, username.length, username)
    if status == 0
      password_length = data.shift
      password_data = data.shift
      password = password_data.bytestr(password_length)
      $logger.info "Found password in KeyChain: #{password}"
    else
      $logger.info "Failed to find password in KeyChain: #{status}"
    end
    
    @username.stringValue = username if username
    @password.stringValue = password if password
  end
  
  ib_action :sync do |sender|
    username = @username.stringValue.to_s
    password = @password.stringValue.to_s
    
    defaults = NSUserDefaults.standardUserDefaults
    defaults.setObject_forKey(username, 'username')
    defaults.synchronize
    
    status = SecKeychainAddGenericPassword(nil, SERVICE.length, SERVICE, username.length, username, password.length, password, nil)
    
    if status == 0
      $logger.info "Password created in KeyChain: #{password}"
    elsif status == ErrSecDuplicateItem
      $logger.info "Password already exists in KeyChain"
      status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, username.length, username)
      if status == 0
        password_length = data.shift
        password_data = data.shift
        item_reference = data.shift #SecKeychainItemRef
        status = SecKeychainItemModifyContent(item_reference, nil, password.length, password)
        if status == 0
          $logger.info "Password updated in KeyChain: #{password}"
        else
          $logger.info "Failed to update password in KeyChain: #{status}"
        end
      else
        $logger.info "Failed to find password in KeyChain: #{status}"
      end
    else
      $logger.info "Failed to create password in KeyChain: #{status}"
    end
    
    Sync.sync(username, password)
    
    @label.stringValue = 'Complete'
  end
  
end