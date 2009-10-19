require 'pathname'

class RealPath
  
  def initialize(command)
    @pathname = Pathname.new(%x[/usr/bin/which #{command}].chomp)
  end
  
  def to_s
    @pathname.realpath.to_s
  end
  
end