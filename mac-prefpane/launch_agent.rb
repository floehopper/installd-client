require 'osx/cocoa'

require 'erb'

require File.expand_path(File.join(File.dirname(__FILE__), 'command'))

module Installd

  class LaunchAgent
  
    include OSX
    
    attr_accessor :start_interval
    attr_accessor :nice_increment
    attr_accessor :run_at_load
    
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
      NSLog("Installd::LaunchAgent: write: #{@bundle_identifier}")
      File.open(plist_path, 'w') do |file|
        file << plist
      end
    end
  
    def load
      NSLog("Installd::LaunchAgent: load: #{plist_path}")
      Command.new(%{#{launchctl} load -w -S Aqua #{plist_path}}).execute
    end
  
    def unload
      NSLog("Installd::LaunchAgent: unload: #{plist_path}")
      if File.exist?(plist_path)
        Command.new(%{#{launchctl} unload -w -S Aqua #{plist_path}}).execute
      end
    end
  
    def start
      NSLog("Installd::LaunchAgent: start: #{@bundle_identifier}")
      Command.new(%{#{launchctl} start #{@bundle_identifier}}).execute
    end
    
    def status
      NSLog("Installd::LaunchAgent: status for: #{@bundle_identifier}")
      status = Command.new(%{#{launchctl} list | /usr/bin/grep #{@bundle_identifier}}).execute rescue ''
      NSLog("Installd::LaunchAgent: status: #{status}")
      status.chomp
    end
    
    def loaded?
      !status.empty?
    end
    
    def pid
      text = status.split("\t")[0]
      return nil unless text && text != '-'
      text.to_i
    end
    
    def running?
      !pid.nil?
    end
    
    def last_exit_code
      text = status.split("\t")[1]
      return nil unless text && text != '-'
      text.to_i
    end
    
    def succeeded?
      last_exit_code == 0
    end
    
    private
    
    def launchctl
      '/bin/launchctl'
    end
    
  end
  
end