class Preferences
  
  include OSX
  
  SERVICE = 'Installd'
  
  DEFAULTS = {
    :username => '',
    :password => '',
    :itunes_directory => File.join(ENV['HOME'], 'Music', 'iTunes')
  }
  
  attr_reader :username
  attr_reader :password
  
  attr_accessor :itunes_directory
  
  def initialize(bundle)
    OSX.load_bridge_support_file(bundle.pathForResource_ofType('Security', 'bridgesupport'))
    
    @defaults = NSUserDefaults.standardUserDefaults
    
    @username = @defaults.stringForKey('username') || DEFAULTS[:username]
    @itunes_directory = @defaults.stringForKey('itunes_directory') || DEFAULTS[:itunes_directory]
    
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
    
    @credentials_changed = false
  end
  
  def save
    @defaults.setObject_forKey(@username, 'username')
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