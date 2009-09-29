require 'osx/cocoa'

require File.expand_path(File.join(File.dirname(__FILE__), 'command'))

module Installd

  class LaunchAgent
  
    include OSX
  
    def initialize(bundle)
      @bundle_identifier = bundle.bundleIdentifier
      sync_script = bundle.pathForResource_ofType('sync', 'sh')
      @plist_path = File.join(ENV['HOME'], 'Library', 'LaunchAgents', "#{@bundle_identifier}.plist")
      start_interval = 24 * 60 * 60
      @plist = %{
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>#{@bundle_identifier}</string>
            <key>ProgramArguments</key>
            <array>
              <string>#{sync_script}</string>
            </array>
            <key>StartInterval</key>
            <integer>#{start_interval}</integer>
          </dict>
        </plist>
      }
    end
  
    def load
      Command.new(%{/bin/launchctl load -w -S Aqua #{@plist_path}}).execute
    end
  
    def unload
      if File.exist?(@plist_path)
        Command.new(%{/bin/launchctl unload -w -S Aqua #{@plist_path}}).execute
      end
    end
  
    def start
      Command.new(%{/bin/launchctl start #{@bundle_identifier}}).execute
    end
  
    def write
      NSLog("Writing launch agent: #{@bundle_identifier}")
      File.open(@plist_path, 'w') do |file|
        file << @plist
      end
    end
  
  end
  
end