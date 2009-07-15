class Preferences
  
  include OSX
  
  SERVICE = 'Installd'
  
  DEFAULTS = { :username => '', :hours_between_syncs => 24 }
  
  attr_accessor :username, :password, :hours_between_syncs
  
  def initialize
    @defaults = NSUserDefaults.standardUserDefaults
    
    @username = @defaults.stringForKey('username') || DEFAULTS[:username]
    @hours_between_syncs = @defaults.integerForKey('hoursBetweenSyncs')
    if @hours_between_syncs == 0
      @hours_between_syncs = DEFAULTS[:hours_between_syncs]
    end
    
    @password = nil
    status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username)
    if status == 0
      password_length = data.shift
      password_data = data.shift
      @password = password_data.bytestr(password_length)
      NSLog("Found password in KeyChain: #{@password}")
    else
      NSLog("Failed to find password in KeyChain: #{status}")
    end
  end
  
  def save
    @defaults.setObject_forKey(@username, 'username')
    @defaults.setInteger_forKey(@hours_between_syncs, 'hoursBetweenSyncs')
    @defaults.synchronize
    
    status = SecKeychainAddGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username, @password.length, @password, nil)
    
    if status == 0
      NSLog("Password created in KeyChain: #{@password}")
    elsif status == ErrSecDuplicateItem
      NSLog("Password already exists in KeyChain")
      status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username)
      if status == 0
        password_length = data.shift
        password_data = data.shift
        item_reference = data.shift
        status = SecKeychainItemModifyContent(item_reference, nil, @password.length, @password)
        if status == 0
          NSLog("Password updated in KeyChain: #{@password}")
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