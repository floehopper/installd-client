module Installd

  class Preferences
  
    include OSX
  
    attr_accessor :username
    attr_accessor :itunes_directory
    attr_accessor :last_sync_status
  
    def initialize(bundle_identifier)
      @bundle_identifier = bundle_identifier
      load
    end
  
    def load
      @username = get_value('username', '')
      @itunes_directory = get_value('itunes_directory', File.join(ENV['HOME'], 'Music', 'iTunes'))
      @last_sync_status = get_value('last_sync_status', '')
    end
  
    def save
      set_value('username', @username)
      set_value('itunes_directory', @itunes_directory)
      set_value('last_sync_status', @last_sync_status)
      synchronize
    end
  
    private
  
    def get_value(key, default)
      (CFPreferencesCopyValue(key, @bundle_identifier, KCFPreferencesCurrentUser, KCFPreferencesAnyHost) || default).to_s
    end
  
    def set_value(key, value)
      CFPreferencesSetValue(key, value, @bundle_identifier, KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
    end
  
    def synchronize
      if CFPreferencesSynchronize(@bundle_identifier, KCFPreferencesCurrentUser, KCFPreferencesAnyHost)
        NSLog("Preferences#synchronize succeeded for #{@bundle_identifier}")
      else
        NSLog("Preferences#synchronize failed for #{@bundle_identifier}")
      end
    end
  
  end
  
end