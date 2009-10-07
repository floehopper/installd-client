require 'osx/cocoa'

module Installd

  class Command
    
    include OSX
  
    def initialize(command)
      @command = command
    end
  
    def execute
      NSLog("Installd::Command: #{@command}")
      output = `#{@command} 2>&1`
      NSLog("Installd::Command: #{output}")
      unless $?.success?
        message = "Installd::Command: Error executing: #{@command}"
        NSLog(message)
        raise message
      end
    end
  
  end
  
end