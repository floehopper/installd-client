require 'osx/cocoa'

require 'erb'

require File.expand_path(File.join(File.dirname(__FILE__), 'command'))

module Installd

  class LaunchAgent
  
    include OSX
    
    attr_accessor :start_interval
    attr_accessor :nice_increment
    
    def initialize(bundle_identifier, script_path)
      @bundle_identifier, @script_path = bundle_identifier, script_path
      yield self if block_given?
    end
    
    def plist_path
      File.join(ENV['HOME'], 'Library', 'LaunchAgents', "#{@bundle_identifier}.plist")
    end
    
    def plist
      template_path = File.expand_path('launch_agent_template.plist.erb', File.dirname(__FILE__))
      template = File.open(template_path).read
      erb = ERB.new(template)
      erb.result(binding)
    end
  
    def write
      NSLog("Writing launch agent: #{@bundle_identifier}")
      File.open(plist_path, 'w') do |file|
        file << plist
      end
    end
  
    def load
      NSLog("Loading launch agent: #{plist_path}")
      Command.new(%{/bin/launchctl load -w -S Aqua #{plist_path}}).execute
    end
  
    def unload
      NSLog("Unloading launch agent: #{plist_path}")
      if File.exist?(plist_path)
        Command.new(%{/bin/launchctl unload -w -S Aqua #{plist_path}}).execute
      end
    end
  
    def start
      NSLog("Starting launch agent: #{@bundle_identifier}")
      Command.new(%{/bin/launchctl start #{@bundle_identifier}}).execute
    end
  
  end
  
end