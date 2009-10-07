require 'osx/cocoa'

module Installd

  class Preferences
  
    include OSX
  
    attr_accessor :username
    attr_accessor :itunes_directory
    attr_accessor :last_sync_status
    attr_accessor :launched_before
    attr_accessor :status_bar_enabled
  
    def initialize(bundle_identifier)
      @bundle_identifier = bundle_identifier
      load
    end
  
    def load
      @username = get_value('username', '').to_s
      @itunes_directory = get_value('itunes_directory', File.join(ENV['HOME'], 'Music', 'iTunes')).to_s
      @last_sync_status = get_value('last_sync_status', 'Not yet synced').to_s
      @launched_before = get_boolean_value('launched_before', false)
      @status_bar_enabled = get_boolean_value('status_bar_enabled', true)
    end
  
    def save
      set_value('username', @username)
      set_value('itunes_directory', @itunes_directory)
      set_value('last_sync_status', @last_sync_status)
      set_boolean_value('launched_before', @launched_before)
      set_boolean_value('status_bar_enabled', @status_bar_enabled)
      synchronize
    end
  
    private
    
    def get_value(key, default)
      CFPreferencesCopyAppValue(key, @bundle_identifier) || default
    end
    
    def get_boolean_value(key, default)
      value = CFPreferencesCopyAppValue(key, @bundle_identifier)
      value ? value.boolValue : default
    end
    
    def set_boolean_value(key, value)
      set_value(key, NSNumber.numberWithBool(value))
    end
  
    def set_value(key, value)
      CFPreferencesSetAppValue(key, value, @bundle_identifier)
    end
  
    def synchronize
      if CFPreferencesAppSynchronize(@bundle_identifier)
        NSLog("Preferences#synchronize succeeded for #{@bundle_identifier}")
      else
        NSLog("Preferences#synchronize failed for #{@bundle_identifier}")
      end
    end
  
  end
  
end