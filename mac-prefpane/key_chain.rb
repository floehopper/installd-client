require 'osx/cocoa'

OSX.load_bridge_support_file(File.expand_path(File.join(File.dirname(__FILE__), 'Security.bridgesupport')))

require 'pathname'

OSX.ns_import 'KeyChainAPI'

module Installd

  class KeyChain
  
    include OSX
  
    SERVICE = 'Installd'
  
    DEFAULT_PASSWORD = ''
  
    attr_accessor :password
  
    def initialize(username)
      @username = username
      load
    end
  
    def load
      status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username)
      if status == 0
        password_length = data.shift
        password_data = data.shift
        @password = password_data.bytestr(password_length)
        NSLog("Installd::KeyChain: Found password")
      else
        NSLog("Installd::KeyChain: Failed to find password: #{status}")
      end
      @password ||= DEFAULT_PASSWORD
    end
  
    def save
      path_to_ruby = Pathname.new(`/usr/bin/which ruby`.chomp).realpath.to_s
      status = KeyChainAPI.alloc.init.addGenericPassword_account_password_otherAppPath(SERVICE, @username, @password, path_to_ruby)
    
      if status == 0
        NSLog("Installd::KeyChain: Password created")
      elsif status == ErrSecDuplicateItem
        NSLog("Installd::KeyChain: Password already exists")
        status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username)
        if status == 0
          password_length = data.shift
          password_data = data.shift
          item_reference = data.shift
          status = SecKeychainItemModifyContent(item_reference, nil, @password.length, @password)
          if status == 0
            NSLog("Installd::KeyChain: Password updated")
          else
            NSLog("Installd::KeyChain: Failed to update password: #{status}")
          end
        else
          NSLog("Installd::KeyChain: Failed to find password: #{status}")
        end
      else
        NSLog("Installd::KeyChain: Failed to create password: #{status}")
      end
    end
  
  end
  
end