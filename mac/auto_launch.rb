class AutoLaunch
  
  include OSX
  
  attr_accessor :enabled
  
  def initialize
    property_list = get_property_list
    @enabled = property_list ? property_list.any? { |app| app['Path'] == app_path } : false
  end
  
  def save
    property_list = get_mutable_property_list
    
    if @enabled
      property_list.addObject(NSDictionary.dictionaryWithObject_forKey(app_path, 'Path'))
    else
      existing_object = property_list.detect { |app| app['Path'] == app_path }
      property_list.removeObject(existing_object) if existing_object
    end
    
    set_property_list(property_list)
    synchronize_preferences
  end
  
  private
  
  def get_property_list
    CFPreferencesCopyValue('AutoLaunchedApplicationDictionary', 'loginwindow', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
  end
  
  def get_mutable_property_list
    property_list = get_property_list
    return property_list ? property_list.mutableCopy : NSMutableArray.alloc.init
  end
  
  def set_property_list(property_list)
    CFPreferencesSetValue('AutoLaunchedApplicationDictionary', property_list, 'loginwindow', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
  end
  
  def synchronize_preferences
    if CFPreferencesSynchronize('loginwindow', KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
      NSLog("Synchronized AutoLaunch preferences")
    else
      NSLog("Failed to synchronize AutoLaunch preferences")
    end
  end
  
  def app_path
    @app_path ||= NSBundle.mainBundle.bundlePath
  end
  
end