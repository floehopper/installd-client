require 'auto_launch'

class Preferences
  
  include OSX
  
  SERVICE = 'Installd'
  
  DEFAULTS = {
    :username => '',
    :password => '',
    :hours_between_syncs => 24,
    :launched_before => false,
    :itunes_directory => File.join(ENV['HOME'], 'Music', 'iTunes')
  }
  
  attr_reader :username, :password, :launched_before
  attr_accessor :hours_between_syncs, :auto_launch_enabled, :itunes_directory
  
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
    @password ||= DEFAULTS[:password]
    
    @auto_launch = AutoLaunch.new
    @auto_launch_enabled = @auto_launch.enabled
    
    @itunes_directory = @defaults.stringForKey('itunes_directory') || DEFAULTS[:itunes_directory]
    
    @launched_before = @defaults.boolForKey('SUHasLaunchedBefore') || DEFAULTS[:launched_before]
    
    @credentials_changed = false
  end
  
  def save
    @defaults.setObject_forKey(@username, 'username')
    @defaults.setInteger_forKey(@hours_between_syncs, 'hoursBetweenSyncs')
    @defaults.setObject_forKey(@itunes_directory, 'itunes_directory')
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
    
    @credentials_changed = false
    
    @auto_launch.enabled = @auto_launch_enabled
    @auto_launch.save
  end
  
  def username=(new_username)
    unless @username == new_username
      @credentials_changed = true
    end
    @username = new_username
  end
  
  def password=(new_password)
    unless @password == new_password
      @credentials_changed = true
    end
    @password = new_password
  end
  
  def credentials_changed?
    @credentials_changed
  end
  
end