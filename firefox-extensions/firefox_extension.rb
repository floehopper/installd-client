require 'hpricot'

module Local
  
  class FirefoxExtension
    
    attr_reader :attributes
    
    def initialize(attributes = {})
      @attributes = attributes
    end
    
    def [](key)
      @attributes[key]
    end
    
    def self.all_by_name
      extensions_pattern = File.join(ENV['HOME'], 'Library', 'Application Support', 'Firefox', '*.default', 'extensions')
      
      app_names = {}
      Dir[extensions_pattern].each do |extension_dir|
        p extension_dir
      end
    end
    
  end
  
end
