OSX.load_bridge_support_file(File.expand_path(File.join(File.dirname(__FILE__), 'Security.bridgesupport')))

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
  attr_accessor :last_sync_status
  
  def initialize
    @username = (CFPreferencesCopyValue('username', 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost) || DEFAULTS[:username]).to_s
    @itunes_directory = (CFPreferencesCopyValue('itunes_directory', 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost) || DEFAULTS[:itunes_directory]).to_s
    @last_sync_status = (CFPreferencesCopyValue('last_sync_status', 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost) || DEFAULTS[:last_sync_status]).to_s
    
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
    CFPreferencesSetValue('username', @username, 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
    CFPreferencesSetValue('itunes_directory', @itunes_directory, 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
    CFPreferencesSetValue('last_sync_status', @last_sync_status, 'com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
    CFPreferencesSynchronize('com.floehopper.installdPrefPane', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
    
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