require 'osx/cocoa'

module Installd

  class Command
    
    include OSX
  
    def initialize(command)
      @command = command
    end
  
    def execute
      NSLog(@command)
      NSLog(`#{@command} 2>&1`)
      unless $?.success?
        message = "Error executing command: #{@command}"
        NSLog(message)
        raise message
      end
    end
  
  end
  
end