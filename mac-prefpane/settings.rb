require 'forwardable'

require File.expand_path(File.join(File.dirname(__FILE__), 'preferences'))
require File.expand_path(File.join(File.dirname(__FILE__), 'key_chain'))

module Installd

  class Settings
  
    extend Forwardable
  
    def_delegator :@preferences, :username
    def_delegator :@preferences, :username=
  
    def_delegator :@preferences, :itunes_directory
    def_delegator :@preferences, :itunes_directory=
  
    def_delegator :@preferences, :last_sync_status
    def_delegator :@preferences, :last_sync_status=
  
    def_delegator :@key_chain, :password
    def_delegator :@key_chain, :password=
  
    def initialize(bundle_identifier)
      @preferences = Preferences.new(bundle_identifier)
      @key_chain = KeyChain.new(@preferences.username)
    end
  
    def load
      @preferences.load
      @key_chain.load
    end
  
    def save
      @preferences.save
      @key_chain.save
    end
  
  end
  
end