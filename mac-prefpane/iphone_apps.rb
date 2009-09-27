require 'osx/cocoa'

require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), 'command'))

module Installd
  
  class IphoneApps
  
    include OSX
  
    def initialize(itunes_directory)
      @itunes_directory = itunes_directory
    end
  
    def extract_data
      FileUtils.mkdir_p('/tmp/installd/')
    
      FileUtils.rm_rf('/tmp/installd/unzipped')
      FileUtils.mkdir_p('/tmp/installd/unzipped')
    
      doc = ''
      files = Dir[File.join(@itunes_directory, 'Mobile Applications', '*.ipa')]
      files.each_with_index do |file, index|
        begin
          app_name = File.basename(file, '.ipa')
          unzip_dir = File.join('/tmp/installd/unzipped', app_name)
          plist = File.join(unzip_dir, 'iTunesMetadata.plist')
      
          Command.new(%{/usr/bin/unzip -d "#{unzip_dir}" "#{file}" iTunesMetadata.plist}).execute
          Command.new(%{/bin/chmod +rw "#{plist}"}).execute
          Command.new(%{/usr/bin/plutil -convert xml1 "#{plist}"}).execute
      
          File.open(plist) do |file|
            file.readline
            file.readline
            doc << file.read
          end
      
          yield index if block_given?
        rescue => exception
          NSLog("Exception handled: #{exception}")
          exception.backtrace.each do |line|
            NSLog("  #{line}")
          end
          NSLog("Skipping: #{file}")
        end
      end
    
      FileUtils.rm_rf('/tmp/installd/unzipped')
    
      doc
    end
  
  end
  
end