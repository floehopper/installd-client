require 'osx/cocoa'

require 'pathname'

module Installd

  class RealPath
  
    include OSX
    
    def initialize(command)
      NSLog("Installd::RealPath: initialize: #{command}")
      path = %x[/usr/bin/which #{command}].chomp
      NSLog("path = #{path}")
      @pathname = Pathname.new(path)
      NSLog("realpath = #{@pathname.realpath}")
    end
  
    def to_s
      @pathname.realpath.to_s
    end
  
  end
  
end