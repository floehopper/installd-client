OSX.load_bridge_support_file(File.expand_path(File.join(File.dirname(__FILE__), 'Security.bridgesupport')))

class KeyChain
  
  include OSX
  
  SERVICE = 'Installd'
  
  DEFAULT_PASSWORD = ''
  
  attr_accessor :password
  
  def initialize(username)
    @username = username
    status, *data = SecKeychainFindGenericPassword(nil, SERVICE.length, SERVICE, @username.length, @username)
    if status == 0
      password_length = data.shift
      password_data = data.shift
      @password = password_data.bytestr(password_length)
      NSLog("Found password in KeyChain: #{@password}")
    else
      NSLog("Failed to find password in KeyChain: #{status}")
    end
    @password ||= DEFAULT_PASSWORD
  end
  
  def save
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